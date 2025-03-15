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


func transformToHEICS(
    cicontext:CIContext,
    imageSource:CGImageSource,
    memoryPool:CMMemoryPool,
    lossyCompressionQuality:Double? = nil,
    to identifier:String = "public.heics"
) throws(HEICModifierError) -> Data {
    
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

    for index in 0..<count {
        

        var ciImage = CIImage(cgImageSource: imageSource, index: index, options: [
            .applyOrientationProperty: true,
            .nearestSampling: false,
            .init(rawValue: "kCIImageExpandToHDR") :true,
        ]).premultiplyingAlpha()

        let cgImage = cicontext.createCGImage(
            ciImage,
            from: ciImage.extent,
            format: .BGRA8,
            colorSpace: .init(name: CGColorSpace.extendedSRGB)
        )!
        var prop = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil) as! [String: Any]
        var imageProp = prop[sourcePropKey] as! [String:Any]
        prop[sourcePropKey] = nil
        defer {
            prop[kCGImageDestinationLossyCompressionQuality as String] = lossyCompressionQuality
            prop[targetPropKey as String] = imageProp
            CGImageDestinationAddImage(destination, cgImage, prop as CFDictionary)
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
    throw .failedToCreateCopy
}


enum HEICModifierError: Error {
    case unsupportedImageType
    case sttsBoxNotFound
    case invalidSTTSStructure
    case failedToCreateDestination
    case invalidEntryStructure
    case failedToCreateCopy
}
