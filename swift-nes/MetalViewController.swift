//
//  Created by Alexandre Frigon on 2018-10-24.
//  Copyright © 2018 Frigstudio. All rights reserved.
//

import Metal
import Cocoa

class MetalViewController: NSViewController {
    private var device: MTLDevice!
    private var metalLayer: CAMetalLayer!
    private var pipelineState: MTLRenderPipelineState!
    private var commandQueue: MTLCommandQueue!
    private var displayLink: DisplayLink!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.device = MTLCreateSystemDefaultDevice()
        
        self.metalLayer = CAMetalLayer()
        self.metalLayer.device = self.device
        self.metalLayer.pixelFormat = .bgra8Unorm
        self.metalLayer.framebufferOnly = true
        self.metalLayer.frame = self.view.layer!.frame
        self.view.layer?.addSublayer(self.metalLayer)
        
        //self.initializeData(width: Float(self.view.layer!.frame.width), height: Float(self.view.layer!.frame.height))
        
        self.pipelineState = self.compilePipeline()
        self.commandQueue = self.device.makeCommandQueue()
        self.displayLink = DisplayLink(onQueue: DispatchQueue.main)
        self.displayLink.callback = self.gameloop
        self.displayLink.start()
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
        self.update()
        autoreleasepool {
            self.render()
        }
    }
    
    private func update() {
        
    }
    
    private func render() {
        let commandBuffer = self.commandQueue.makeCommandBuffer()
        
        guard let drawable = self.metalLayer.nextDrawable() else { return }
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 100.0, blue: 100.0, alpha: 1.0)
        
        let encoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        encoder?.setRenderPipelineState(pipelineState)
        
//        for row in self.cells {
//            for cell in row {
//                cell.draw(encoder)
//            }
//        }
        
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
