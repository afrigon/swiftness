//
//  Created by Alexandre Frigon on 2018-10-24.
//  Copyright © 2018 Frigstudio. All rights reserved.
//

import Metal
import Cocoa
import CoreText

class MetalViewController: NSViewController {
    override var acceptsFirstResponder: Bool { return true }
    private var device: MTLDevice!
    private var metalLayer: CAMetalLayer!
    private var pipelineState: MTLRenderPipelineState!
    private var commandQueue: MTLCommandQueue!
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
        let vertexProgram = defaultLibrary?.makeFunction(name: "static_vertex")
        let fragmentProgram = defaultLibrary?.makeFunction(name: "static_fragment")
        
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
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        let encoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        encoder?.setRenderPipelineState(pipelineState)
        
        encoder?.setVertexBytes([0.0, -1.0, -1.0, 1.0, 1.0, 1.0], length: 6 * MemoryLayout<Float>.size, index: 0)
        encoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder?.endEncoding()
        
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}

class Quad {
    private var vbo: MTLBuffer?
    
    init(x: Float, y: Float, width: Float, height: Float, _ device: MTLDevice) {
        var vao = [Float]()
        vao.append(x)
        vao.append(y)
        
        vao.append(x + width)
        vao.append(y)
        
        vao.append(x + width)
        vao.append(y + height)
        
        vao.append(x)
        vao.append(y)
        
        vao.append(x + width)
        vao.append(y + height)
        
        vao.append(x)
        vao.append(y + height)
        
        self.vbo = device.makeBuffer(bytes: vao, length: vao.count * MemoryLayout<Float>.size, options: [])
    }
    
    public func draw(_ color: Float, _ encoder: MTLRenderCommandEncoder?) {
        encoder?.setVertexBuffer(self.vbo, offset: 0, index: 0)
        encoder?.setFragmentBytes([color], length: 32, index: 0)
        encoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}
