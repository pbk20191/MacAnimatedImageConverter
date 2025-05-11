//
//  SharedModel.swift
//  MacAnimatedImageConverter
//
//  Created by 박병관 on 5/11/25.
//

import CoreMedia
import CoreImage
import Observation

@Observable
class SharedModel {
    
    let pmaOnCiContext:CIContext
    let pmaOffCiContext:CIContext
    let memoryPool:CMMemoryPool
    
    
    
    init(pmaOnCiContext: CIContext, pmaOffCiContext: CIContext, memoryPool: CMMemoryPool) {
        self.pmaOnCiContext = pmaOnCiContext
        self.pmaOffCiContext = pmaOffCiContext
        self.memoryPool = memoryPool
    }
    
    init() {
        self.pmaOffCiContext = CIContext(
            options: [
                .outputPremultiplied: false,
                .workingColorSpace: CGColorSpace(name: CGColorSpace.coreMedia709)!,
            ]
        )
        self.pmaOnCiContext = CIContext(
            options: [
                .outputPremultiplied: true,
            ]
        )
        self.memoryPool = CMMemoryPoolCreate(options: nil)
    }
}