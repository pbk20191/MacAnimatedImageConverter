//
//  AnimatedImageTransferable.swift
//  AnimateImageData
//
//  Created by 박병관 on 3/14/25.
//  Copyright © 2025 Augmented Code. All rights reserved.
//

import CoreTransferable
import ImageIO
import UniformTypeIdentifiers



struct AnimatedImageImportable: Transferable, Hashable {
    
    
     

    

    
    var content:DataSourceType
    var animatedType:AnimatedType
    
    
    func makeSentFile() async throws -> SentTransferredFile {
        let data:Data
        switch content {
        case .data(let memory):
            data = memory
        case .url(let uRL):
            return SentTransferredFile(uRL, allowAccessingOriginalFile: false)
        }
        let fileName = suggestedFilename ?? "whatever"
        guard let fileNameExtension = animatedType.utType.preferredFilenameExtension else {
            throw TransferError.unsupportedFileType
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).\(fileNameExtension)")
        try data.write(to: url)
        return SentTransferredFile(url, allowAccessingOriginalFile: true)
    }
    
    func makeData() async throws -> Data {
        switch content {
        case .data(let data):
            return data
        case .url(let url):
            return try Data(contentsOf: url)
        }
    }
    
    
    static var transferRepresentation: some TransferRepresentation {

        FileRepresentation(importedContentType: .png, shouldAttemptToOpenInPlace: true) {
            try Self.scanStatusFor(url: $0.file, kCGImagePropertyPNGDictionary as String)
            return Self(content: .url($0.file), animatedType: .apng)
        }
        DataRepresentation(importedContentType: .png)  {
            try Self.scanStatusFor(data: $0, kCGImagePropertyPNGDictionary as String)
            return Self(content: .data($0), animatedType: .apng)
        }
        FileRepresentation(importedContentType: .heics, shouldAttemptToOpenInPlace: true)  {
            try Self.scanStatusFor(url: $0.file, kCGImagePropertyHEICSDictionary as String)

            return Self(content: .url($0.file), animatedType: .heics)
        }
        
        DataRepresentation(importedContentType: .heics) {
            try Self.scanStatusFor(data: $0, kCGImagePropertyHEICSDictionary as String)
            return Self(content: .data($0), animatedType: .heics)
        }
        FileRepresentation(importedContentType: .gif, shouldAttemptToOpenInPlace: true) {
            try Self.scanStatusFor(url: $0.file, kCGImagePropertyGIFDictionary as String)

            return Self(content: .url($0.file), animatedType: .gif)
        }
        DataRepresentation(importedContentType: .gif)  {
            try Self.scanStatusFor(data: $0, kCGImagePropertyGIFDictionary as String)
            return Self(content: .data($0), animatedType: .gif)
        }
        
        FileRepresentation(importedContentType: .webP, shouldAttemptToOpenInPlace: true) {
            try Self.scanStatusFor(url: $0.file, kCGImagePropertyWebPDictionary as String)

            return Self(content: .url($0.file), animatedType: .webp)
        }
        DataRepresentation(importedContentType: .webP) {
            try Self.scanStatusFor(data: $0, kCGImagePropertyWebPDictionary as String)
            return Self(content: .data($0), animatedType: .webp)
        }
        FileRepresentation(importedContentType: UTType("public.avif")!, shouldAttemptToOpenInPlace: true) {
            try Self.scanStatusFor(url: $0.file, kCGImagePropertyAVISDictionary as String)

            return Self(content: .url($0.file), animatedType: .webp)
        }
        DataRepresentation(importedContentType: UTType("public.avif")!) {
            try Self.scanStatusFor(data: $0, kCGImagePropertyAVISDictionary as String)
            return Self(content: .data($0), animatedType: .avif)
        }

    }
    
    static func scanStatusFor(data:Data, _ dictKey: String) throws {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw TransferError.canNotCreateImageSource
        }
        try scanStatusFor(source: source, dictKey)
    }
    
    static func scanStatusFor(url:URL, _ dictKey: String) throws {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw TransferError.canNotCreateImageSource
        }
        try scanStatusFor(source: source, dictKey)
    }
    
    static func scanStatusFor(source:CGImageSource, _ dictKey: String) throws {
        guard let prop = CGImageSourceCopyProperties(source, nil) as? [String:Any] else {
            throw TransferError.imageDecodingFailed
        }
        let contentProp = prop[dictKey as String] as? [String:Any]
        if contentProp?["CanAnimate"] as? Bool == true {
            return
        }
        
        guard let frameArray = contentProp?["FrameInfo"] as? [[String:Any]], !frameArray.isEmpty else {
            throw TransferError.notAnimatableImage
        }
        if frameArray[0]["DelayTime"] == nil {
            throw TransferError.notAnimatableImage
        }
    }
    
    
}


enum TransferError:Error {
    case unsupportedFileType
    case canNotCreateImageSource
    case imageDecodingFailed
    case notAnimatableImage
}
