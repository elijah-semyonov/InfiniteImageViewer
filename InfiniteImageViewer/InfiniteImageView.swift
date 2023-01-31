//
//  InfiniteImageView.swift
//  InfiniteImageViewer
//
//  Created by Elijah Semyonov on 31/01/2023.
//

import UIKit
import Metal

struct InfiniteImageTileIndex {
    let x: Int
    let y: Int
}

protocol InfiniteImageViewTileDataProvider {
    func tileImageData(at index: InfiniteImageTileIndex) async throws -> Data
}

class InfiniteImageView: UIView {
    class override var layerClass: AnyClass {
        CAMetalLayer.self
    }
    
    var contentOffset: CGPoint = .zero
    
    private var metalLayer: CAMetalLayer {
        layer as! CAMetalLayer
    }
    
    private let tileDataProvider: InfiniteImageViewTileDataProvider
    private let device: MTLDevice
    private let library: MTLLibrary
    private let commandQueue: MTLCommandQueue
    private let backgroundRenderPipelineState: MTLRenderPipelineState
    private let inflightSemaphore = DispatchSemaphore(value: 3)
    private var screenScale: CGFloat? {
        didSet {
            updateDrawableSize()
        }
    }
    private var displayLink: CADisplayLink?
    private var backgroundUniforms: BackgroundUniforms {
        .init(viewportMin: .init(0.0, 0.0), viewportMax: Vec2f(Float(bounds.width), Float(bounds.height)))
    }
    
    init?(tileDataProvider: InfiniteImageViewTileDataProvider) {
        self.tileDataProvider = tileDataProvider
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            return nil
        }
        
        guard let library = device.makeDefaultLibrary() else {
            return nil
        }
        
        guard let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        
        self.device = device
        self.library = library
        self.commandQueue = commandQueue
        
        guard let backgroundRenderPipelineState = Self.loadRenderPipelineState(name: "background", device: device, library: library) else {
            return nil
        }
        
        self.backgroundRenderPipelineState = backgroundRenderPipelineState
        
        super.init(frame: .zero)
        
        metalLayer.pixelFormat = .bgra8Unorm_srgb
        
        isUserInteractionEnabled = true
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(panGestureRecognizer)
    }
    
    required init?(coder: NSCoder) {
        nil
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if let window {
            screenScale = window.screen.nativeScale
            
            enableDisplayLink(framesPerSecond: window.screen.maximumFramesPerSecond)
        } else {
            disableDisplayLink()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        updateDrawableSize()
    }
    
    private static func loadRenderPipelineState(name: String, device: MTLDevice, library: MTLLibrary) -> MTLRenderPipelineState? {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        
        guard let vertexFunction = library.makeFunction(name: "\(name)_vf") else {
            return nil
        }
        
        guard let fragmentFunction = library.makeFunction(name: "\(name)_ff") else {
            return nil
        }
        
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        
        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func updateDrawableSize() {
        guard let screenScale else { return }
        metalLayer.drawableSize = .init(width: bounds.width * screenScale, height: bounds.height * screenScale)
    }
    
    private func enableDisplayLink(framesPerSecond: Int) {
        guard displayLink == nil else {
            return
        }
        
        let displayLink = CADisplayLink { [weak self] in
            self?.render()
        }
        
        let framesPerSecond = Float(framesPerSecond)
        
        displayLink.preferredFrameRateRange = .init(minimum: 10.0, maximum: framesPerSecond, preferred: framesPerSecond)
        
        self.displayLink = displayLink
        
        displayLink.add(to: .main, forMode: .common)
    }
    
    private func disableDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        print(gestureRecognizer)
    }
    
    private func render() {
        guard metalLayer.drawableSize.width >= 1.0 && metalLayer.drawableSize.height >= 1.0 else {
            return
        }
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        
        _ = inflightSemaphore.wait(timeout: .distantFuture)
        
        let drawable = metalLayer.nextDrawable()!
        let texture = drawable.texture
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .dontCare
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
                
        encoder.setRenderPipelineState(backgroundRenderPipelineState)
        encoder.setFragmentValue(backgroundUniforms, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        
        encoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.addCompletedHandler { _ in
            self.inflightSemaphore.signal()
        }
        
        commandBuffer.commit()
    }
}
