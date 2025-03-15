//
//  InfiniteAnimationImageView.swift
//  AnimateImageData
//
//  Created by 박병관 on 3/12/25.
//  Copyright © 2025 Augmented Code. All rights reserved.
//


import Foundation
import SwiftUI
import ImageIO


struct InfiniteAnimationImageView: View, Equatable {
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.param == rhs.param && lhs.label == rhs.label
    }
    
    
    enum Param: Hashable {
        case data(Data)
        case url(URL)
    }
    
    struct ContextData {
        var ids = 0
        var index = 0
        var pausing = false
    }
    
    private var ids:Int {
        get { context.header.ids }
        nonmutating _modify { yield &context.header.ids }
        nonmutating set { context.header.ids = newValue }
    }
    
    private var index:Int {
        get { context.header.index }
        nonmutating _modify { yield &context.header.index }
        nonmutating set { context.header.index = newValue }
    }
    
    private var pausing:Bool {
        get { context.header.pausing }
        nonmutating _modify { yield &context.header.pausing }
        nonmutating set { context.header.pausing = newValue }
    }
    
    @State private var context:ManagedBuffer<ContextData,Void> = .create(minimumCapacity: 0) { _ in
        .init()
    }
    @State private var cgImage:CGImage?

    @Environment(\.displayScale) private var displayScale
    @Environment(\.imageScale) private var imageScale
    var param:Param
    var label:Text
    
    var body: some View {
        Group {
            if let cgImage {
                Image(cgImage, scale: displayScale, label: label)
                    .resizable()
            } else {
                Spacer()
                    .frame(width: 0, height: 0)
            }
        }.onAppear {
            self.pausing = false
            launchAnimation(param)
        }.onChange(of: param) { newValue in
            index = 0
            launchAnimation(newValue)

        }.onDisappear {
            self.pausing = true
        }
        .frame(idealWidth: .init(cgImage?.width ?? 1), idealHeight: .init( cgImage?.height ?? 1))
    }

    
    private func launchAnimation(_ param:Param) {
        ids &+= 1
//        CGImage().o
        let snapId = ids
        let count:Int
        switch param {
        case .data(let data):
            if let source = CGImageSourceCreateWithData(data as CFData, nil) {
                count = CGImageSourceGetCount(source)
            } else {
                count = 0
            }
        case .url(let uRL):
            if let source = CGImageSourceCreateWithURL(uRL as CFURL, nil) {
                count = CGImageSourceGetCount(source)
            } else {
                count = 0
            }
        }
        
        let block:CGImageSourceAnimationBlock = { index, cgImage, exiter in
            guard ids == snapId else {
                exiter.pointee = true
                return
            }
            self.index = index
            self.cgImage = cgImage
//            if #available(iOS 16.7, *) {
//                exiter.pointee = self.pausing
//                return
//            }
            
//            if index == count - 1 {
//                exiter.pointee = true
//            } else {
                exiter.pointee = self.pausing
//            }
        }
        var dictionary = [:] as [String:Any]
        dictionary[kCGImageAnimationStartIndex as String] = 50
//        dictionary[kCGImageAnimationLoopCount as String] = 3
        let status:CGImageAnimationStatus?
        switch param {
        case .data(let data):
            status = .init(rawValue: CGAnimateImageDataWithBlock(data as CFData, dictionary as CFDictionary, block))
            break
        case .url(let url):
            status = .init(rawValue: CGAnimateImageAtURLWithBlock(url as CFURL, dictionary as CFDictionary, block))
            break
        }
        
    }
    
    init(url:URL, label:Text) {
        self.param = .url(url)
        self.label = label
    }
    
    init(data:Data, label:Text) {
        self.param = .data(data)
        self.label = label
    }
   
    
}
