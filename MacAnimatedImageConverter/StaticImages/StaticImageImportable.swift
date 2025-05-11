//
//  StaticImageImportable.swift
//  MacAnimatedImageConverter
//
//  Created by 박병관 on 5/11/25.
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers
import ImageIO

struct StaticImageImportable: Transferable, Hashable {
    
    
    var content:DataSourceType
    var uttype:UTType
    var suggestedFilename:String?
    
    
    func makeSentFile() async throws -> SentTransferredFile {
        let data:Data
        switch content {
        case .data(let memory):
            data = memory
        case .url(let uRL):
            return SentTransferredFile(uRL, allowAccessingOriginalFile: false)
        }
        let fileName = suggestedFilename ?? "whatever"
//        if #available(macOS 15.2, iOS 18.2, visionOS 2.2, tvOS 18.2, watchOS 11.2, *) {
//             suggestedFilename ?? "whatever"
//        } else {
//            "whatever"
//        }
        guard let fileNameExtension = uttype.preferredFilenameExtension else {
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
        FileRepresentation(contentType: .image, shouldAttemptToOpenInPlace: true) {
            try await $0.makeSentFile()
        } importing: {
            guard let source = CGImageSourceCreateWithURL($0.file as CFURL, nil) else {
                
                throw TransferError.canNotCreateImageSource
            }
            guard
                let identifier = CGImageSourceGetType(source) as String?,
                let uttype = UTType(identifier)
            else {
                throw TransferError.imageDecodingFailed
            }
            if $0.isOriginalFile {
                var block = Self.init(content: .url($0.file), uttype: uttype)
                block.suggestedFilename = $0.file.deletingPathExtension().lastPathComponent
                return block
            }
            let data = try Data.init(contentsOf: $0.file)
            
            var block =  Self.init(content: .data(data), uttype: uttype)
            block.suggestedFilename = $0.file.deletingPathExtension().lastPathComponent

            return block
        }

        DataRepresentation(contentType: .image) {
            try await $0.makeData()
        } importing: {
            guard let source = CGImageSourceCreateWithData($0 as CFData, nil) else {
            
            throw TransferError.canNotCreateImageSource
            }
            guard
                let identifier = CGImageSourceGetType(source) as String?,
                let uttype = UTType(identifier)
            else {
                throw TransferError.imageDecodingFailed
            }
            
            return Self.init(content: .data($0), uttype: uttype)
        }

        ProxyRepresentation<Self, NSImage> {
            switch $0.content {
            case .data(let data):
                if let image = NSImage(data: data) {
                    return image
                }
                throw TransferError.imageDecodingFailed
            case .url(let url):
                return .init(byReferencing: url)
            }
        } importing: {
            
            guard let data = $0.tiffRepresentation else {
                throw TransferError.imageDecodingFailed
            }
            return .init(content: .data(data), uttype: .tiff)
        }

        
    }
    

}


#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif


struct StaticHeicImageRep: Transferable, Hashable {
    
    
    var content:DataSourceType
    var suggestedFilename:String?

    
    func makeSentFile() async throws -> SentTransferredFile {
        let data:Data
        switch content {
        case .data(let memory):
            data = memory
        case .url(let uRL):
            return SentTransferredFile(uRL, allowAccessingOriginalFile: false)
        }
        let fileName = suggestedFilename ?? "whatever"
//        if #available(macOS 15.2, iOS 18.2, visionOS 2.2, tvOS 18.2, watchOS 11.2, *) {
//             suggestedFilename ?? "whatever"
//        } else {
//            "whatever"
//        }
        guard let fileNameExtension = UTType.heic.preferredFilenameExtension else {
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
        FileRepresentation(contentType: .image, shouldAttemptToOpenInPlace: true) {
            try await $0.makeSentFile()
        } importing: {
            guard let source = CGImageSourceCreateWithURL($0.file as CFURL, nil) else {
                
                throw TransferError.canNotCreateImageSource
            }
            guard
                let identifier = CGImageSourceGetType(source) as String?,
                let uttype = UTType(identifier)
            else {
                throw TransferError.imageDecodingFailed
            }
            if $0.isOriginalFile {
                return Self.init(content: .url($0.file))
            }
            let data = try Data.init(contentsOf: $0.file)
            
            return Self.init(content: .data(data))
        }

        DataRepresentation(contentType: .heic) {
            try await $0.makeData()
        } importing: {
            guard let source = CGImageSourceCreateWithData($0 as CFData, nil) else {
            
            throw TransferError.canNotCreateImageSource
            }
            guard
                let identifier = CGImageSourceGetType(source) as String?,
                let uttype = UTType(identifier)
            else {
                throw TransferError.imageDecodingFailed
            }
            
            return Self.init(content: .data($0))
        }

        ProxyRepresentation<Self, NSImage> {
            switch $0.content {
            case .data(let data):
                if let image = NSImage(data: data) {
                    return image
                }
                throw TransferError.imageDecodingFailed
            case .url(let url):
                return .init(byReferencing: url)
            }
        } importing: {
            
            guard let data = $0.tiffRepresentation else {
                throw TransferError.imageDecodingFailed
            }
            return .init(content: .data(data))
        }

        
    }
    
#if os(macOS)
func makePlatformImage() -> NSImage {
    switch self.content {
    case .data(let data):
        return .init(data: data)!
    case .url(let uRL):
        return .init(byReferencing: uRL)
    }
}
#else
func makePlatformImage() -> UIImage {
    switch self.content {
    case .data(let data):
        return .init(data: data)
    case .url(let uRL):
        return .init(contentsOfFile : uRL.path())
    }
}

#endif
}
