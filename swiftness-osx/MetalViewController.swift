//
//    MIT License
//
//    Copyright (c) 2018 Alexandre Frigon
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.
//

import MetalKit
import Cocoa
import CoreText
import simd

struct Vertex {
    let position: vector_float2
    let textureCoordinate: vector_float2
}

class MetalViewController: NSViewController {
    override var acceptsFirstResponder: Bool { return true }
    private var device: MTLDevice!
    private var metalLayer: CAMetalLayer!
    private var pipelineState: MTLRenderPipelineState!
    private var commandQueue: MTLCommandQueue!
    private var texture: MTLTexture!
    private var samplerState: MTLSamplerState!
    private var vbo: MTLBuffer!
    private var displayLink: DisplayLink!
    private var timestamp: CFTimeInterval = 0.0
    private var fps: UInt32 = 0
    private let overlay = OverlayLayer()
    private let nes = NintendoEntertainmentSystem()
    private var displayOverlay = false
    
    override func loadView() {
        let view = NSView()
        view.wantsLayer = true
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.device = MTLCreateSystemDefaultDevice()
        
        self.metalLayer = CAMetalLayer()
        self.metalLayer.device = self.device
        self.metalLayer.pixelFormat = .bgra8Unorm
        self.metalLayer.framebufferOnly = true
        self.view.layer?.addSublayer(self.metalLayer)
        
        let vao: [Vertex] = [
            Vertex(position: vector_float2(1, -1), textureCoordinate: vector_float2(1, 1)),
            Vertex(position: vector_float2(-1,  -1), textureCoordinate: vector_float2(0, 1)),
            Vertex(position: vector_float2(-1, 1), textureCoordinate: vector_float2(0, 0)),
            Vertex(position: vector_float2(1, -1), textureCoordinate: vector_float2(1, 1)),
            Vertex(position: vector_float2(-1, 1), textureCoordinate: vector_float2(0, 0)),
            Vertex(position: vector_float2(1, 1), textureCoordinate: vector_float2(1, 0))
        ]
        self.vbo = self.device.makeBuffer(bytes: vao, length: MemoryLayout<Vertex>.size * vao.count, options: [.storageModeShared])
        
        let url = Bundle.main.url(forResource: "000", withExtension: "png")!
        let loader = MTKTextureLoader(device: self.device)
        do {
            self.texture = try loader.newTexture(URL: url, options: nil)
        } catch {
            print(error)
        }
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerDescriptor.minFilter = .nearest
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        self.samplerState = self.device.makeSamplerState(descriptor: samplerDescriptor)
        
        
        self.overlay.fontSize = 14
        self.overlay.font = NSFont(name: "Menlo", size: 14)
        self.view.layer?.addSublayer(self.overlay)
        
        self.pipelineState = self.compilePipeline()
        self.commandQueue = self.device.makeCommandQueue()
        self.displayLink = DisplayLink(onQueue: DispatchQueue.main)
        self.displayLink.callback = self.gameloop
        self.displayLink.start()
    }
    
    func toggleOverlay() {
        self.displayOverlay = !self.displayOverlay
        if self.displayOverlay {
            self.view.layer?.addSublayer(self.overlay)
        } else {
            self.overlay.removeFromSuperlayer()
        }
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 99: // F3
            self.toggleOverlay()
        default:
            print(event.keyCode)
        }
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        self.overlay.frame = CGRect(x: 10, y: 5, width: self.view.layer!.frame.width - 20, height: self.view.layer!.frame.height - 10)
        self.metalLayer.frame = self.view.layer!.frame
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        self.displayLink.suspend()
    }
    
    private func compilePipeline() -> MTLRenderPipelineState {
        let defaultLibrary = self.device.makeDefaultLibrary()
        let vertexProgram = defaultLibrary?.makeFunction(name: "textured_vertex")
        let fragmentProgram = defaultLibrary?.makeFunction(name: "textured_fragment")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexProgram
        pipelineDescriptor.fragmentFunction = fragmentProgram
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        guard let pipelineState = try? self.device.makeRenderPipelineState(descriptor: pipelineDescriptor) else {
            fatalError("Could not compile pipeline with curent configuration")
        }
        
        return pipelineState
    }
    
    private func gameloop() {
        if self.timestamp == 0.0 { self.timestamp = CACurrentMediaTime() }
        
        let newTimestamp = CACurrentMediaTime()
        let deltaTime = newTimestamp - self.timestamp
        self.timestamp = newTimestamp
        self.fps = UInt32((1 / deltaTime))
        
        self.update(deltaTime)
        
        if self.displayOverlay {
            self.overlay.update(items: OverlayItems(fps: self.fps, nes: self.nes), deltaTime)
        }
        
        autoreleasepool {
            self.render()
        }
    }
    
    private func update(_ deltaTime: CFTimeInterval) {
    }
    
    private func render() {
        let commandBuffer = self.commandQueue.makeCommandBuffer()
        
        guard let drawable = self.metalLayer.nextDrawable() else { return }
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)
        
        let encoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        encoder?.setRenderPipelineState(pipelineState)
        
        encoder?.setVertexBuffer(self.vbo, offset: 0, index: 0)
        encoder?.setFragmentTexture(self.texture, index: 0)
        encoder?.setFragmentSamplerState(self.samplerState, index: 0)
        encoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        encoder?.endEncoding()
        
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
