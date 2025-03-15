//
//  WebPFileWrapper.swift
//  AnimateImageData
//
//  Created by 박병관 on 3/15/25.
//  Copyright © 2025 Augmented Code. All rights reserved.
//
import CoreTransferable
import ImageIO
import UniformTypeIdentifiers

public struct WebPFileWrapper:Hashable, Transferable, AnimatedImageItemProtocol{
        
        static func validateSource(_ source: DataSourceType) async throws {
            switch source {
            case .data(let data):
                try Self.scanStatusFor(data: data, kCGImagePropertyWebPDictionary as String)
            case .url(let uRL):
                try Self.scanStatusFor(url: uRL, kCGImagePropertyWebPDictionary as String)
    
            }
        }
        
        var content: DataSourceType
        
        static var uniformTypeIdentifier: UTType {
            .webP
        }
        
        public static var transferRepresentation: some TransferRepresentation {
            fileTransfer
            dataTransfer
    
            
        }
        
}


