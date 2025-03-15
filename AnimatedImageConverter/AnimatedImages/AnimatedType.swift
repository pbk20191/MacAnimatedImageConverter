//
//  AnimatedType.swift
//  AnimateImageData
//
//  Created by 박병관 on 3/15/25.
//  Copyright © 2025 Augmented Code. All rights reserved.
//

import UniformTypeIdentifiers
import ImageIO

enum AnimatedType:Hashable {
    case heics
    case apng
    case gif
    case webp
    case avif
    
    
    var utType:UTType {
        switch self {
        case .heics:
            return .heics
        case .apng:
            return .png
        case .gif:
            return .gif
        case .webp:
            return .webP
            case .avif:
            return .init("public.avif")!
        }
    }
}
