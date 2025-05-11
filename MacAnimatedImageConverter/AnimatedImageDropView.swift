//
//  AnimatedImageDropView.swift
//  PbkImageConverter
//
//  Created by 박병관 on 3/14/25.
//  Copyright © 2025 Augmented Code. All rights reserved.
//

import SwiftUI

import SwiftUI
import UniformTypeIdentifiers
import AppKit
import AVFoundation
import Combine


struct AnimatedImageDropView: View {
    @State private var image: AnimatedImageImportable? = nil
    @State private var outputUrl:URL? = nil
    @State private var presentAlert = false
    @State private var error:ImageDropError?
    @State private var lossyFactor = 0.5
    @State private var outputDetailItem = ItemWrapperIdentifier?.none
    @State private var destinationIdentifer:UTType? = nil
    @State private var processing = false
    @Environment(SharedModel.self) private var model 
    
    let destinationTypes:[UTType] = [
        .heics, .png, .gif
    ]
    
    var body: some View {
        VStack {
            Text("Drag & Drop Animated Images")
                .font(.headline)
                .padding()
            Text("APNG, HEICS, AVIF, GIF, AWebP is Supported for Decoding")
            Section {
                Slider(value: $lossyFactor, in: 0...1.0, minimumValueLabel: Text("0"), maximumValueLabel: Text("1")) {
                    Text("보존율")
                }
                TextField("input preservation", value: $lossyFactor, format: .percent)
                    .frame(width: 150)
                    .onChange(of: lossyFactor) { newValue in
                        if newValue < 0 {
                            lossyFactor = 0
                        }
                        if newValue > 1 {
                            lossyFactor = 1
                        }
                    }
            } header: {
                Text("lossy compression config")
            }

            ZStack {
                Rectangle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundColor(.gray)
                    .frame(width: 300, height: 300)
                
                if let image  {

                    Group {
                        switch image.content {
                        case .data(let data):
                            InfiniteAnimationImageView(data: data, label: Text("Animated"))
                        case .url(let url):
                            InfiniteAnimationImageView(url: url, label: Text("Animated"))
                        }
                    }
                        .frame(width: 300, height: 300)
                        .allowsHitTesting(false)
                } else {
                    Text("No Image")
                        .foregroundColor(.gray)
                }
            }
            .dropDestination(for: AnimatedImageImportable.self, action: { items, location in
                self.image = items.first
                
                return !items.isEmpty
            })
            .padding()
            Text("awebp, avics is not Supported for Encoding because Apple ImageIO does not support that feature")
                .lineLimit(nil)
            Picker("Destination Type", selection: $destinationIdentifer) {
                ForEach(destinationTypes, id: \.self) { type in
                    Text(type.preferredFilenameExtension ?? "unknown")
                        .tag(type)
                }
            }
            Button  {
                if let image, let uttype = self.destinationIdentifer {
                    let memoryPool = model.memoryPool
                    let lossy = self.lossyFactor
                    let cicontext = model.pmaOffCiContext
                    let exportAs:AnimatedType? = switch uttype {
                    case .png:
                        .apng
                    case .gif:
                        .gif
                    case .heics:
                        .heics
                    case .webP:
                        .webp
                    default:
                        nil
                    }
                    guard let exportAs else { return }
                    Task.detached {
                        await MainActor.run {
                            processing = true
                        }
                        do {
                            
                            let imageSource:CGImageSource?
                            switch image.content {
                            case .data(let data):
                                imageSource = CGImageSourceCreateWithData(data as CFData, nil)
                            case .url(let uRL):
                                imageSource = CGImageSourceCreateWithURL(uRL as CFURL, nil)
                            }
                            
                            let data = try transformToHEICS(
                                cicontext: cicontext,
                                imageSource: imageSource!,
                                memoryPool: memoryPool,
                                lossyCompressionQuality: lossy,
                                to: uttype.identifier
                            )
                            
                            await MainActor.run {
                                self.outputDetailItem = .init(item: .init(content: .data(data), animatedType: exportAs))
                            }
                        } catch {
                            await MainActor.run {
                                self.error = ImageDropError(innerError: error)
                                self.presentAlert = true
                            }

                        }
                        await MainActor.run {
                            processing = false
                        }
                    }
                }
            } label: {
                if processing {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    Text("Convert")
                }
            }
            .disabled(image == nil || destinationIdentifer == nil || processing)
            .padding()
            
            .sheet(item: $outputDetailItem) {
                DetailSheetView(item: $0.item)
                    .presentationSizing(.fitted)
                    .frame(minWidth: 150, maxWidth: 1920, minHeight: 150, maxHeight: 1080)
            }
           

 
        }
        .frame(width: 400)
    
        .alert(isPresented: $presentAlert, error: error) {
            Button("ok") {
                presentAlert = false
            }
        }

    }
    
    



    

}


/*
 
 
 ["public.jpeg", "public.png", "com.compuserve.gif", "com.canon.tif-raw-image", "com.adobe.raw-image", "com.dxo.raw-image", "com.canon.cr2-raw-image", "com.canon.cr3-raw-image", "com.leafamerica.raw-image", "com.hasselblad.fff-raw-image", "com.hasselblad.3fr-raw-image", "com.nikon.raw-image", "com.nikon.nrw-raw-image", "com.pentax.raw-image", "com.samsung.raw-image", "com.sony.raw-image", "com.sony.sr2-raw-image", "com.sony.arw-raw-image", "com.sony.axr-raw-image", "com.epson.raw-image", "com.kodak.raw-image", "public.tiff", "public.jpeg-2000", "com.apple.atx", "org.khronos.astc", "org.khronos.ktx", "org.khronos.ktx2", "public.avci", "public.jpeg-xl", "public.avif", "public.avis", "public.heic", "public.heics", "public.heif", "com.canon.crw-raw-image", "com.fuji.raw-image", "com.panasonic.raw-image", "com.panasonic.rw2-raw-image", "com.leica.raw-image", "com.leica.rwl-raw-image", "com.konicaminolta.raw-image", "com.olympus.sr-raw-image", "com.olympus.or-raw-image", "com.olympus.raw-image", "com.phaseone.raw-image", "com.microsoft.ico", "com.microsoft.bmp", "com.apple.icns", "com.adobe.photoshop-image", "com.microsoft.cur", "com.truevision.tga-image", "com.ilm.openexr-image", "org.webmproject.webp", "com.sgi.sgi-image", "public.radiance", "public.pbm", "public.mpo-image", "public.pvr", "com.microsoft.dds", "com.apple.pict"]
 
 
 ["public.jpeg", "public.png", "com.compuserve.gif", "public.tiff", "public.jpeg-2000", "com.apple.atx", "org.khronos.ktx", "org.khronos.ktx2", "org.khronos.astc", "com.microsoft.dds", "public.heic", "public.heics", "com.microsoft.ico", "com.microsoft.bmp", "com.apple.icns", "com.adobe.photoshop-image", "com.adobe.pdf", "com.truevision.tga-image", "com.ilm.openexr-image", "public.pbm", "public.pvr"]
 
 */
