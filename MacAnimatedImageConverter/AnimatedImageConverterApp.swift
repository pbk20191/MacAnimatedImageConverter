//
//  AnimatedImageConverterApp.swift
//  AnimatedImageConverter
//
//  Created by 박병관 on 3/15/25.
//

import SwiftUI
import SDWebImageWebPCoder

@main
struct AnimatedImageConverterApp: App {
    var body: some Scene {
        WindowGroup {
            ImageDropView()
        }
    }
    
    init () {
        
        SDImageCodersManager.shared.addCoder(SDImageWebPCoder.shared)
        SDImageCodersManager.shared.addCoder(SDImageAWebPCoder.shared)
    }
    
}
