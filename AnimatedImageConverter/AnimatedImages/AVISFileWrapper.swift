//
//  AVISFileWrapper.swift
//  PbkImageConverter
//
//  Created by 박병관 on 3/15/25.
//  Copyright © 2025 Augmented Code. All rights reserved.
//

import CoreTransferable
import ImageIO
import UniformTypeIdentifiers

public struct AVISFileWrapper:Hashable, Transferable, AnimatedImageItemProtocol{
        
        static func validateSource(_ source: DataSourceType) async throws {
            switch source {
            case .data(let data):
                try Self.scanStatusFor(data: data, kCGImagePropertyAVISDictionary as String)
            case .url(let uRL):
                try Self.scanStatusFor(url: uRL, kCGImagePropertyAVISDictionary as String)
    
            }
        }
        
        var content: DataSourceType
        
        static var uniformTypeIdentifier: UTType {
            .init("public.avif")!
        }
        
        public static var transferRepresentation: some TransferRepresentation {
            fileTransfer
            dataTransfer
    
            
        }
        
}

