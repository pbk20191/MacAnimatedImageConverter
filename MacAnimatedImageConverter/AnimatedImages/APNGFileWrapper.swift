//
//  APNGFileWrapper.swift
//  PbkImageConverter
//
//  Created by 박병관 on 3/14/25.
//  Copyright © 2025 Augmented Code. All rights reserved.
//

import Foundation
import ImageIO
import CoreTransferable
import UniformTypeIdentifiers

public struct APNGFileWrapper:Hashable, Transferable, AnimatedImageItemProtocol{
    
    
    static func validateSource(_ source: DataSourceType) async throws {
        switch source {
        case .data(let data):
            try Self.scanStatusFor(data: data, kCGImagePropertyPNGDictionary as String)
        case .url(let uRL):
            try Self.scanStatusFor(url: uRL, kCGImagePropertyPNGDictionary as String)

        }
    }
    
    
    var content: DataSourceType
    
    
    static var uniformTypeIdentifier: UTType {
        .png
    }
    
    public static var transferRepresentation: some TransferRepresentation {
        fileTransfer
        dataTransfer

        
    }
    
}





