//
//  DetailSheetView.swift
//  AnimateImageData
//
//  Created by 박병관 on 3/15/25.
//  Copyright © 2025 Augmented Code. All rights reserved.
//
import SwiftUI

struct DetailSheetView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @GestureState private var magnifyBy = MagnifyData()
    
    struct MagnifyData {
        
        var scale = 1.0 as CGFloat
        var point = UnitPoint.center
    }
    
    @State private var dragExportEnabled = true
    var item:AnimatedImageImportable
    
    var body: some View {
        VStack {
            if dragExportEnabled {
                Text("Drag to Export")
            } else {
                Text("Zoom to magnify")
            }
            Group {
                
                switch item.content {
                case .data(let data):
                    InfiniteAnimationImageView(data: data, label: Text("Animated"))
                        .fixedSize()
                case .url(let url):
                    InfiniteAnimationImageView(url: url, label: Text("Animated"))
                        .fixedSize()
                }
            }
            .zoomable(isEnabled: !dragExportEnabled)
            .overlay {
                if  dragExportEnabled {
                    Color.white.opacity(0.01)
                        .contentShape(Rectangle())
                        .modifier(ExportAnimatedImageModifier(item: item))
                }
                
            }
            HStack {
                Button(dragExportEnabled ? "Enable Magnify" : "Enable Drag&Drop") {
                    dragExportEnabled.toggle()
                }
                Button("Close") {
                    dismiss()
                }
            }
        }.padding()

    }
    
}
