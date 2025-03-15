//
//  SharedModel.swift
//  MacAnimatedImageConverter
//
//  Created by 박병관 on 3/15/25.
//
import Metal
import CoreMedia
import CoreImage


@Observable
class SharedModel {
    
//    let pmaOnCiContext:CIContext
    let pmaOffCiContext:CIContext
    let memoryPool:CMMemoryPool
    let commandqueue:any MTLCommandQueue
    let metalTextureCache:CVMetalTextureCache
    
    private(set) var bufferPool: CVPixelBufferPool?
    private var bufferPoolWidth: Int = 0
    private var bufferPoolHeight: Int = 0
    
    init() {
        var textureCache:CVMetalTextureCache?
        self.commandqueue = MTLCreateSystemDefaultDevice()!.makeCommandQueue()!
        self.pmaOffCiContext = CIContext(
            mtlCommandQueue: self.commandqueue,
            options: [
                .outputPremultiplied: false,
                .workingColorSpace: CGColorSpace(name: CGColorSpace.extendedDisplayP3)!,
            ]
        )
        
        
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, self.commandqueue.device, nil, &textureCache)

//        self.pmaOnCiContext = CIContext(
//            options: [
//                .outputPremultiplied: true,
//            ]
//        )
        self.memoryPool = CMMemoryPoolCreate(options: nil)
        self.metalTextureCache = textureCache!
    }
    
    private func updateBufferPool(newWidth: Int, newHeight: Int) {
        var attributes: [NSString: Any] = [:]
        attributes[kCVPixelBufferPixelFormatTypeKey] = kCVPixelFormatType_32BGRA
        attributes[kCVPixelBufferWidthKey] = newWidth
        attributes[kCVPixelBufferHeightKey] = newHeight
        attributes[kCVPixelBufferIOSurfacePropertiesKey] = [:]
        attributes[kCVPixelBufferCGImageCompatibilityKey] = true
        attributes[kCVPixelBufferMetalCompatibilityKey] = true
        attributes[kCVPixelBufferCGBitmapContextCompatibilityKey] = true

        attributes[kCVPixelBufferMemoryAllocatorKey] = CMMemoryPoolGetAllocator(memoryPool)
        let cvReturn = CVPixelBufferPoolCreate(nil, nil, attributes as CFDictionary?, &bufferPool)

        assert(cvReturn == kCVReturnSuccess)
        bufferPoolWidth = newWidth
        bufferPoolHeight = newHeight
    }
    
    func ensureBufferPoolCapacity(width: Int, height: Int) {
        if width != bufferPoolWidth || height != bufferPoolHeight {
            updateBufferPool(newWidth: width, newHeight: height)
        }
    }
}
