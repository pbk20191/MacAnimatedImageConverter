//
//  HEICModifierError.swift
//  AnimateImageData
//
//  Created by 박병관 on 3/13/25.
//  Copyright © 2025 Augmented Code. All rights reserved.
//


//
//  File.swift
//  LocalToolKit
//
//  Created by 박병관 on 3/12/25.
//

import Foundation
import ImageIO
import CoreImage
import UniformTypeIdentifiers
import CoreMedia
import Metal
import VideoToolbox

func transformToHEICS(
    cicontext:CIContext,
    commandQueue:MTLCommandQueue,
    bufferPool:CVPixelBufferPool,
    texturePool:CVMetalTextureCache,
    imageSource:CGImageSource,
    memoryPool:CMMemoryPool,
    lossyCompressionQuality:Double? = nil,
    to identifier:String = "public.heics"
) throws -> Data {
    let count = CGImageSourceGetCount(imageSource)
    let sourcePropKey:String
    let typeId = CGImageSourceGetType(imageSource) as String?
    switch typeId {
    case "public.png":
        sourcePropKey = kCGImagePropertyPNGDictionary as String
    case "public.heics":
        sourcePropKey = kCGImagePropertyHEICSDictionary as String
    case "public.avis":
        sourcePropKey = kCGImagePropertyAVISDictionary as String
    case UTType.gif.identifier:
        sourcePropKey = kCGImagePropertyGIFDictionary as String
    case UTType.webP.identifier:
        sourcePropKey = kCGImagePropertyWebPDictionary as String
    case UTType.png.identifier:
        sourcePropKey = kCGImagePropertyPNGDictionary as String
    case UTType.tiff.identifier:
        sourcePropKey = kCGImagePropertyTIFFDictionary as String
    case UTType.heif.identifier:
        sourcePropKey = kCGImagePropertyHEIFDictionary as String
    default:
        throw HEICModifierError.unsupportedImageType
    }
    let targetPropKey:String
    switch identifier {
    case "public.png":
        targetPropKey = kCGImagePropertyPNGDictionary as String
    case "public.heics":
        targetPropKey = kCGImagePropertyHEICSDictionary as String
    case "public.avis", "public.avif":
        targetPropKey = kCGImagePropertyAVISDictionary as String
    case UTType.gif.identifier:
        targetPropKey = kCGImagePropertyGIFDictionary as String
    case UTType.webP.identifier:
        targetPropKey = kCGImagePropertyWebPDictionary as String
    case UTType.png.identifier:
        targetPropKey = kCGImagePropertyPNGDictionary as String
    case UTType.tiff.identifier:
        targetPropKey = kCGImagePropertyTIFFDictionary as String
    case UTType.heif.identifier:
        targetPropKey = kCGImagePropertyHEIFDictionary as String
        
    default:
        throw HEICModifierError.unsupportedImageType
    }
    let metaData = CGImageMetadataCreateMutable()
    
    
//    let tag = CGImageMetadataTagCreate(kCGImageMetadataNamespaceXMPBasic, kCGImageMetadataPrefixXMPBasic, "thumbnailindex" as CFString, .string, 48 as CFNumber)!
//                       assert( CGImageMetadataSetTagWithPath(metaData, nil, "\(kCGImageMetadataPrefixXMPBasic as String):thumbnailindex" as CFString, tag))
//                        assert(
//                            CGImageMetadataSetValueWithPath(metaData, nil, "\(kCGImageMetadataPrefixXMPBasic as String):thumbnailindex" as CFString, 48 as CFNumber)
//                        )
//    let tiffTag = CGImageMetadataTagCreate(kCGImageMetadataNamespaceTIFF, nil, "ThumbnailIndex" as CFString, .string, 48 as CFNumber)!
//    assert( CGImageMetadataSetTagWithPath(metaData, nil, "\(kCGImageMetadataPrefixTIFF as String):ThumbnailIndex" as CFString, tiffTag))
//    CGImageMetadata
    var props = CGImageSourceCopyProperties(imageSource, nil) as! [String: Any]
    props[kCGImagePropertyHEICSDictionary as String] = props[sourcePropKey]
    props[sourcePropKey] = nil
//    props[propKey]
//    props[kCGImageTiff]
    let fileData:NSMutableData = CFDataCreateMutable(CMMemoryPoolGetAllocator(memoryPool), 0)
//    let destionation
    guard let destination = CGImageDestinationCreateWithData(fileData, identifier as CFString, count, [
        kCGImageDestinationOptimizeColorForSharing : false,
        kCGImageDestinationPreserveGainMap  : false,
        
    ] as CFDictionary) else {
        throw HEICModifierError.failedToCreateDestination
    }
    CGImageDestinationSetProperties(destination, props as CFDictionary)
    let commandBuffer = commandQueue.makeCommandBuffer()!
    let imageArray = try (0..<count).map { index in
        var ciImage = CIImage(cgImageSource: imageSource, index: index, options: [
            .applyOrientationProperty: true,
            .nearestSampling: false,
            .init(rawValue: "kCIImageExpandToHDR") :true,
        ]).premultiplyingAlpha()
            
        func flipImage(ciImage: CIImage) -> CIImage {
            let transform = CGAffineTransform(scaleX: 1, y: -1) // Flip Y-axis
                .translatedBy(x: 0, y: -ciImage.extent.height) // Shift back into view

            return ciImage.transformed(by: transform)
        }
        ciImage = flipImage(ciImage: ciImage)
        var pixelBuffer:CVPixelBuffer? = nil
        var cvRet = CVPixelBufferPoolCreatePixelBuffer(nil, bufferPool, &pixelBuffer)
        if cvRet != kCVReturnSuccess {
            throw CoreVideoError(rawValue: cvRet)!
        }
        var texture:CVMetalTexture?
        cvRet = CVMetalTextureCacheCreateTextureFromImage(nil, texturePool, pixelBuffer!, nil, .bgra8Unorm, Int(ciImage.extent.width), Int(ciImage.extent.height), 0, &texture)
        if cvRet != kCVReturnSuccess {
            throw CoreVideoError(rawValue: cvRet)!
        }
        commandBuffer.addCompletedHandler { [texture] _ in
            withExtendedLifetime(texture, {})
        }
        let destination = CIRenderDestination(mtlTexture: CVMetalTextureGetTexture(texture!)!, commandBuffer: commandBuffer)
        try cicontext.startTask(toRender: ciImage, to: destination)
        return pixelBuffer!
    }
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    for index in 0..<count {
        
        let cvBuffer = imageArray[index]
        var cgImage:CGImage? = nil
        var retCode = VTCreateCGImageFromCVPixelBuffer(cvBuffer, options: nil, imageOut: &cgImage)
        
        var prop = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil) as! [String: Any]
        var imageProp = prop[sourcePropKey] as! [String:Any]
        prop[sourcePropKey] = nil
        defer {
            prop[kCGImageDestinationLossyCompressionQuality as String] = lossyCompressionQuality
            prop[targetPropKey as String] = imageProp
            CGImageDestinationAddImage(destination, cgImage!, prop as CFDictionary)
        }
//        imageProp[kCGImagePropertyNamedColorSpace as String] = CGColorSpace.extendedDisplayP3
        if let metaData = CGImageSourceCopyMetadataAtIndex(imageSource, index, nil) {
            prop[kCGImageDestinationMetadata as String] = metaData
        }
        props[kCGImageDestinationPreserveGainMap as String] = false
    }

    CGImageDestinationFinalize(destination)

    if let data = CFDataCreateCopy(CMMemoryPoolGetAllocator(memoryPool), fileData) {
        
        return data as Data
    }
    throw HEICModifierError.failedToCreateCopy
}


enum HEICModifierError: Error {
    case unsupportedImageType
    case sttsBoxNotFound
    case invalidSTTSStructure
    case failedToCreateDestination
    case invalidEntryStructure
    case failedToCreateCopy
}


struct CoreVideoError: RawRepresentable, Error {
    
    init?(rawValue: CVReturn) {
        if rawValue == kCVReturnSuccess {
            return nil
        }
        self.rawValue = rawValue
    }
    
    var rawValue: CVReturn
    
    var localizedDescription: String {
        switch rawValue {
        case kCVReturnRetry:
            return "kCVReturnRetry"
        case kCVReturnUnsupported:
            return "kCVReturnUnsupported"
        case kCVReturnInvalidSize:
            return "kCVReturnInvalidSize"
        case kCVReturnInvalidDisplay:
            return "kCVReturnInvalidDisplay"
        case kCVReturnInvalidArgument:
            return "kCVReturnInvalidArgument"
        case kCVReturnAllocationFailed:
            return "kCVReturnAllocationFailed"
        case kCVReturnInvalidPixelFormat:
            return "kCVReturnInvalidPixelFormat"
        case kCVReturnPoolAllocationFailed:
            return "kCVReturnPoolAllocationFailed"
        case kCVReturnInvalidPoolAttributes:
            return "kCVReturnInvalidPoolAttributes"
        case kCVReturnDisplayLinkNotRunning:
            return "kCVReturnDisplayLinkNotRunning"
        case kCVReturnDisplayLinkAlreadyRunning:
            return "kCVReturnDisplayLinkAlreadyRunning"
        case kCVReturnInvalidPixelBufferAttributes:
            return "kCVReturnInvalidPixelBufferAttributes"
        case kCVReturnDisplayLinkCallbacksNotSet:
            return "kCVReturnDisplayLinkCallbacksNotSet"
        case kCVReturnWouldExceedAllocationThreshold:
            return "kCVReturnWouldExceedAllocationThreshold"
        case kCVReturnPixelBufferNotMetalCompatible:
            return "kCVReturnPixelBufferNotMetalCompatible"
        case kCVReturnPixelBufferNotOpenGLCompatible:
            return "kCVReturnPixelBufferNotOpenGLCompatible"
        default:
            return "unknown CVReturn (\(rawValue))"
        }
    }
}
