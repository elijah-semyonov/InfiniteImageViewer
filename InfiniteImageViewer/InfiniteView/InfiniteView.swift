//
//  InfiniteImageView.swift
//  InfiniteImageViewer
//
//  Created by Elijah Semyonov on 31/01/2023.
//

import UIKit
import Metal

let tileSize: Float = 200.0

class InfiniteView: UIView {
    class override var layerClass: AnyClass {
        CAMetalLayer.self
    }
    
    var contentOffset: CGPoint {
        get {
            CGPoint(x: CGFloat(positioning.center.x), y: CGFloat(positioning.center.y))
        }
        
        set {
            positioning.center = .init(Float(newValue.x), Float(newValue.y))
        }
    }
    
    private var metalLayer: CAMetalLayer {
        layer as! CAMetalLayer
    }
    
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
    private var panStartLocation: CGPoint?
    private var lastPanLocation: CGPoint?
    private var panStartContentOffset: CGPoint?
    private var panInertia: CGPoint = .zero
    private var isPanning = false
    private var hasPanningJustEnded = false
    private var zoomScale: CGFloat = 1.0 {
        didSet {
            updatePositioningSpan()
        }
    }
    private var pinchStartZoomScale: CGFloat?
    private var displayLink: CADisplayLink?
    private var framesPerSecond = 60
    private var visibleSet: InfiniteViewVisibleSet
    private var positioning = InfiniteViewPositioning(
        center: .zero,
        span: .zero
    ) {
        didSet {
            updateVisibleSet()
        }
    }
    private var backgroundUniforms: BackgroundUniforms {
        .init(
            viewportMin: positioning.center - positioning.span / 2.0,
            viewportMax: positioning.center + positioning.span / 2.0,
            tileSize: tileSize
        )
    }
    
    init?(tileDataProvider: InfiniteViewTileDataProvider) {
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
        
        guard let backgroundRenderPipelineState = loadRenderPipelineState(name: "background", device: device, library: library) else {
            return nil
        }
        
        guard let visibleSet = InfiniteViewVisibleSet(provider: tileDataProvider, device: device, library: library) else {
            return nil
        }
        
        self.visibleSet = visibleSet
        
        self.backgroundRenderPipelineState = backgroundRenderPipelineState
        
        super.init(frame: .zero)
        
        metalLayer.pixelFormat = .bgra8Unorm_srgb
        
        isUserInteractionEnabled = true
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        panGestureRecognizer.maximumNumberOfTouches = 1
        addGestureRecognizer(panGestureRecognizer)
        
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        addGestureRecognizer(pinchGestureRecognizer)
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
        updatePositioningSpan()
    }
    
    private func updatePositioningSpan() {
        positioning.span = .init(Float(bounds.width * zoomScale), Float(bounds.height * zoomScale))
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
        
        self.framesPerSecond = framesPerSecond
        
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
        switch gestureRecognizer.state {
        case .began:
            isPanning = true
            panInertia = .zero
            panStartLocation = gestureRecognizer.location(in: self)
            lastPanLocation = panStartLocation
            panStartContentOffset = contentOffset
        case .changed:
            guard let panStartLocation, let panStartContentOffset, let lastPanLocation else {
                return
            }
            let panOffset = gestureRecognizer.location(in: self) - panStartLocation
            contentOffset = panStartContentOffset - panOffset * zoomScale
            panInertia = (gestureRecognizer.location(in: self) - lastPanLocation) * CGFloat(framesPerSecond)
            self.lastPanLocation = gestureRecognizer.location(in: self)
        case .ended, .failed, .cancelled:
            isPanning = false
            hasPanningJustEnded = true
            break
        default:
            break
        }
    }
    
    @objc private func handlePinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            pinchStartZoomScale = zoomScale
        case .changed:
            guard let pinchStartZoomScale else {
                return
            }
            
            let newZoomScale = pinchStartZoomScale / gestureRecognizer.scale
            
            if newZoomScale < 0.5 {
                zoomScale = 0.5
            } else if newZoomScale > 4.0 {
                zoomScale = 4.0
            } else {
                zoomScale = newZoomScale
            }
        case .ended, .failed, .cancelled:
            break
        default:
            break
        }
    }
    
    private func updateVisibleSet() {
        visibleSet.update(using: positioning)
    }
    
    private func render() {
        guard metalLayer.drawableSize.width >= 1.0 && metalLayer.drawableSize.height >= 1.0 else {
            return
        }
        
        let secondsPerFrame = 1.0 / Float(framesPerSecond)
        let inertiaDampeningCoef: Float = 0.91
        let fpsAdjustedDampeningCoef = pow(inertiaDampeningCoef, secondsPerFrame / (1.0 / 60.0))
        
        if !isPanning {
            if !hasPanningJustEnded {
                panInertia = panInertia * CGFloat(fpsAdjustedDampeningCoef)
                contentOffset = contentOffset - panInertia * CGFloat(secondsPerFrame) * zoomScale
            } else {
                hasPanningJustEnded.toggle()
            }
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
        
        visibleSet.encode(to: encoder)
        
        encoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.addCompletedHandler { _ in
            self.inflightSemaphore.signal()
        }
        
        commandBuffer.commit()
    }
}
