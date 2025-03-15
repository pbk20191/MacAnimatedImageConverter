//
//  AnimatedImageItemProtocol.swift
//  AnimateImageData
//
//  Created by 박병관 on 3/14/25.
//  Copyright © 2025 Augmented Code. All rights reserved.
//

import CoreTransferable
import ImageIO
import UniformTypeIdentifiers


protocol AnimatedImageItemProtocol: Hashable, Sendable, Transferable {
    
    var content:DataSourceType { get }
    
    static var uniformTypeIdentifier: UTType { get }
    
    init(content:DataSourceType) throws
    
    static func validateSource(_ source:DataSourceType) async throws
}

extension AnimatedImageItemProtocol {
    
    static var fileTransfer: FileRepresentation<Self> {
        FileRepresentation(contentType: uniformTypeIdentifier, shouldAttemptToOpenInPlace: true) {
            
            try await Self.validateSource($0.content)
            
            switch $0.content {
            case .url(let url):
                return SentTransferredFile(url, allowAccessingOriginalFile: false)
            case .data(let data):
                
                let fileName = $0.suggestedFilename ?? "whatever"
                guard let fileNameExtension = uniformTypeIdentifier.preferredFilenameExtension else {
                    throw TransferError.unsupportedFileType
                }
                let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).\(fileNameExtension)")
                try data.write(to: url)
                return SentTransferredFile(url, allowAccessingOriginalFile: true)
            }
        } importing: {
            try await Self.validateSource(.url($0.file))
            return try Self.init(content: .url($0.file))
        }

    }
    
    static var dataTransfer: DataRepresentation<Self> {
        .init(contentType: uniformTypeIdentifier) {
            switch $0.content {
            case .data(let data):
                return data
            case .url(let url):
                return try Data(contentsOf: url)
            }
        } importing: {
            try await Self.validateSource(.data($0))
            return try Self.init(content: .data($0))
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
