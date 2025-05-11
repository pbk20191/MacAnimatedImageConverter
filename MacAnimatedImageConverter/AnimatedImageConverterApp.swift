//
//  AnimatedImageConverterApp.swift
//  AnimatedImageConverter
//
//  Created by 박병관 on 3/15/25.
//

import SwiftUI

@main
struct AnimatedImageConverterApp: App {
    
    
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    
    @State private var selection:NavigationImageDestionation = .animationTarget
    @State private var sharedModel = SharedModel()
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                NavigationLink("AnimatedImage", value: NavigationImageDestionation.animationTarget)
                NavigationLink("Static Images", value: NavigationImageDestionation.staticTarget)

            }.navigationTitle("Menu")
        } detail: {
            switch selection {
            case .animationTarget:
                AnimatedImageDropView()
            case .staticTarget:
                StaticImagesDropView()
            
            }
        }.environment(sharedModel)

    }
}

enum NavigationImageDestionation: Hashable, BitwiseCopyable, Sendable, Codable {
    
    case animationTarget
    case staticTarget
}
