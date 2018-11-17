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

import Cocoa
import Metal
import simd

struct Vertex {
    let position: vector_float2
    let textureCoordinate: vector_float2
    static var size: Int { return MemoryLayout<Vertex>.size }
    static var quad: [Vertex] {
        return [
            Vertex(position: vector_float2(1, -1), textureCoordinate: vector_float2(1, 1)),
            Vertex(position: vector_float2(-1,  -1), textureCoordinate: vector_float2(0, 1)),
            Vertex(position: vector_float2(-1, 1), textureCoordinate: vector_float2(0, 0)),
            Vertex(position: vector_float2(1, -1), textureCoordinate: vector_float2(1, 1)),
            Vertex(position: vector_float2(-1, 1), textureCoordinate: vector_float2(0, 0)),
            Vertex(position: vector_float2(1, 1), textureCoordinate: vector_float2(1, 0))
        ]
    }
}

class MetalRenderer: Renderer {
    private var device: MTLDevice! = nil
    private var pipelineState: MTLRenderPipelineState! = nil
    private var commandQueue: MTLCommandQueue! = nil

    private var vertexBufferObject: MTLBuffer! = nil
    private var samplerState: MTLSamplerState! = nil
    private var textureDescriptor: MTLTextureDescriptor! = nil
    private var textureRegion: MTLRegion! = nil
    private var texture: MTLTexture! = nil
    private var textureSize: Int = 2048

    private let clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    private let pixelFormat: MTLPixelFormat = .bgra8Unorm
    private let shaderName = "textured"
    let layer = CAMetalLayer()

    init?() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return nil
        }

        self.device = device
        self.configureLayer()
        self.createQuadBuffer()
        self.compileShaderPipeline()
        self.createCommandQueue()
        self.createSamplerState()
        self.configureTextureDescriptor()
    }

    private func configureLayer() {
        self.layer.device = self.device
        self.layer.pixelFormat = self.pixelFormat
        self.layer.framebufferOnly = true
    }

    private func createQuadBuffer() {
        let vertexArrayObject: [Vertex] = Vertex.quad

        guard let buffer = self.device.makeBuffer(bytes: vertexArrayObject, length: Vertex.size * vertexArrayObject.count, options: [.storageModeShared]) else {
            fatalError("Could not create the metal renderer instance")
        }

        self.vertexBufferObject = buffer
    }

    private func compileShaderPipeline() {
        let defaultLibrary = self.device.makeDefaultLibrary()
        let vertexProgram = defaultLibrary?.makeFunction(name: "\(self.shaderName)_vertex")
        let fragmentProgram = defaultLibrary?.makeFunction(name: "\(self.shaderName)_fragment")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexProgram
        pipelineDescriptor.fragmentFunction = fragmentProgram
        pipelineDescriptor.colorAttachments[0].pixelFormat = self.pixelFormat

        guard let pipelineState = try? self.device.makeRenderPipelineState(descriptor: pipelineDescriptor) else {
            fatalError("Could not compile pipeline with curent configuration")
        }

        self.pipelineState = pipelineState
    }

    private func createCommandQueue() {
        guard let commandQueue = self.device.makeCommandQueue() else {
            fatalError("Could not create command queue for metal renderer")
        }

        self.commandQueue = commandQueue
    }

    private func createSamplerState() {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerDescriptor.minFilter = .nearest
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear

        guard let samplerState = self.device.makeSamplerState(descriptor: samplerDescriptor) else {
            fatalError("Could not create sampler state for metal renderer")
        }

        self.samplerState = samplerState
    }

    private func configureTextureDescriptor() {
        self.textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: self.pixelFormat,
                                                                          width: self.textureSize,
                                                                          height: self.textureSize,
                                                                          mipmapped: false)
        self.textureRegion = MTLRegionMake2D(0,
                                             0,
                                             self.textureSize,
                                             self.textureSize)

        guard let texture = self.device.makeTexture(descriptor: self.textureDescriptor) else {
            fatalError("Could not create texture object for metal renderer")
        }

        self.texture = texture
    }

    private func createCommandEncoder(_ renderFunction: (MTLRenderCommandEncoder) -> ()) {
        guard let commandBuffer = self.commandQueue.makeCommandBuffer() else {
            print("Could not create command buffer for metal renderer")
            return
        }

        guard let drawable = self.layer.nextDrawable() else {
            print("Could not fetch next drawable for metal renderer")
            return
        }

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = self.clearColor

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            print("Could not create encoder for metal renderer")
            return
        }

        renderFunction(encoder)

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func draw(_ image: [Byte]) {
        if image.count == self.textureSize * self.textureSize {
            self.texture.replace(region: self.textureRegion,
                                 mipmapLevel: 0,
                                 withBytes: image,
                                 bytesPerRow: self.textureSize)
        }

        self.createCommandEncoder { encoder in
            encoder.setRenderPipelineState(self.pipelineState)

            encoder.setVertexBuffer(self.vertexBufferObject, offset: 0, index: 0)
            encoder.setFragmentTexture(self.texture, index: 0)
            encoder.setFragmentSamplerState(self.samplerState, index: 0)

            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            encoder.endEncoding()
        }
    }
}
