//
//  ExportAnimatedImageModifier.swift
//  AnimateImageData
//
//  Created by 박병관 on 3/15/25.
//  Copyright © 2025 Augmented Code. All rights reserved.
//
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

struct ExportAnimatedImageModifier: ViewModifier {
    
    var item:AnimatedImageImportable
    
    func body(content: Content) -> some View {
        switch item.animatedType {
        case .heics:
            content
                .draggable(HEICSFileWrapper(content: item.content)) {
                    previewImage?.resizable()
                }
        case .apng:
            content
                .draggable(APNGFileWrapper(content: item.content)) {
                    previewImage?.resizable()
                }
        case .gif:
            content
                .draggable(GIFFileWrapper(content: item.content)) {
                    previewImage?.resizable()
                }
        case .webp:
            content
                
                .draggable(WebPFileWrapper(content: item.content)) {
                    previewImage?.resizable()
                }
        case .avif:
            content
                .draggable(AVISFileWrapper(content: item.content)) {
                    previewImage?.resizable()
                }
        }
    }
    
    private var previewImage: Image? {
        switch item.content {
        case .data(let data):
#if os(macOS)
            
            if let image =  NSImage(data: data) {
                return Image(nsImage: image)
            }
            #else
            if let image = UIImage(data: data) {
                return Image(uiImage: image)
            }
            #endif
            return nil

        case .url(let uRL):
        #if os(macOS)
            if let image = NSImage(contentsOf: uRL) {
                return Image(nsImage: image)
            }
            #else
            if let image = UIImage(contentsOfFile: uRL.path) {
                return Image(uiImage: image)
            }
            #endif
            return nil
        }
    }
    
}
