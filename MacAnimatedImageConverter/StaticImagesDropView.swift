//
//  StaticImagesDropView.swift
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


struct StaticImagesDropView: View {
    @State private var images = [ImportOnlyWrapper]()
    @State private var presentAlert = false
    @State private var error:ImageDropError?
    @State private var lossyFactor = 0.5
    @State private var outputItems = ContiguousArray<ExportOnlyWrapper>()
    @State private var processing = false
    @State private var exporting = false
    @Environment(SharedModel.self) private var model
    

    var body: some View {
        VStack {
            Text("Drag & Drop static Images")
                .font(.headline)
                .padding()
            Text("png, avif, jpeg, tiff, webp, photoshop ... etc is Supported for Decoding")
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
                HStack{
                    Button("Clear") {
                        outputItems = []
                        images = []
                    }.disabled(processing)
                    
                    Button("Export") {
                        self.exporting = true
                    }.disabled(outputItems.isEmpty)
                }
            } header: {
                Text("lossy compression config")
            }

            if images.isEmpty && outputItems.isEmpty {
                ZStack {
                    Rectangle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundColor(.gray)
                        .frame(width: 300, height: 300)
                    Text("Drop Image Here!")
                }
                
                
                .dropDestination(for: ImportOnlyWrapper.self, action: { items, location in
                    self.images = items
                    
                    return !items.isEmpty
                })
                .padding()
            } else if outputItems.isEmpty {
                Text("input")
                List($images, id: \.id, editActions: .all) { $item in
                   
                    HStack {
                        SmallImage1View(item: item.item)
                    }.frame(height: 100)
                    
                    
                }
                Button  {
                    let uttype = UTType.heic
                    let snapShot = self.images
                    if !snapShot.isEmpty {
                        let memoryPool = model.memoryPool
                        let lossy = self.lossyFactor
                        let cicontext = model.pmaOffCiContext

                        Task.detached {
                            await MainActor.run {
                                processing = true
                            }
                            do {
                             
                                let results = try await withThrowingTaskGroup(of: StaticHeicImageRep.self, returning: ContiguousArray<ExportOnlyWrapper>.self) { group in
                                    for item in snapShot {
                                        
                                        let success = group.addTaskUnlessCancelled {
                                            let imageSource:CGImageSource?
                                            let names = item.item.suggestedFilename
                                            switch item.item.content {
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
                                            var item = StaticHeicImageRep.init(content: .data(data))
                                            item.suggestedFilename = names
                                            return item
                                        }
                                        if !success {
                                            throw CancellationError()
                                        }
                                    }
                                    var container = ContiguousArray<ExportOnlyWrapper>()
                                    for try await data in group {
  
                                        container.append(
                                            .init(item: data)
                                        )
                                    }
                                    return container
                                }
                                await MainActor.run {
                                    self.outputItems = results
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
                .disabled(self.images.isEmpty || processing)
                .padding()
            } else {
                Text("output")
                List($outputItems, id: \.id, editActions: .all) { $item in
                    
                    HStack {
                        Text("Drag me")
                        SmallImage2View(item: item.item)
                    }
                        .draggable(item.item)
                        .frame(height: 100)
                    
                }
            }



           

 
        }
        .frame(width: 400)
    
        .fileExporter(isPresented: $exporting, items: self.outputItems, contentTypes: [.heic]) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                self.error = .init(innerError: error)
                self.presentAlert = true
            }
        }
        .alert(isPresented: $presentAlert, error: error) {
            Button("ok") {
                presentAlert = false
            }
        }

    }
    
    

    struct ExportOnlyWrapper: Transferable, Identifiable {
        
        let item:StaticHeicImageRep
        
        let id = UUID()
        
        var suggestedFilename:String? {
            item.suggestedFilename
        }
        
        static var transferRepresentation: some TransferRepresentation {
            ProxyRepresentation<Self, StaticHeicImageRep>
                .init(exporting: \.item, importing: { .init(item: $0)})
        }
        
    }

    struct ImportOnlyWrapper: Transferable, Identifiable {
        let item:StaticImageImportable
        let id = UUID()
        
        var suggestedFilename:String? {
            item.suggestedFilename
        }
        
        static var transferRepresentation: some TransferRepresentation {
            ProxyRepresentation<Self, StaticImageImportable>.init(exporting: \.item, importing: { .init(item: $0) })
        }
    }
 
    
    struct SmallImage1View: View {
        
        let item:StaticImageImportable
        @State private var platformImage: NSImage?
        
        var body: some View {
            VStack {
                if let p = platformImage {
                    Image.init(nsImage: p)
                        .resizable()
                } else {
                    Spacer().frame(width: 1, height: 1)
                }
            }.onChange(of: item, initial: true) { oldValue, newValue in
                switch newValue.content {
                case .data(let data):
                    platformImage = .init(data: data)
                case .url(let url):
                    platformImage = .init(byReferencing: url)
                }
            }
        }
        
    }
    
    struct SmallImage2View: View {
        
        let item:StaticHeicImageRep
        @State private var platformImage: NSImage?
        
        var body: some View {
            VStack {
                if let p = platformImage {
                    Image.init(nsImage: p)
                        .resizable()
                } else {
                    Spacer().frame(width: 1, height: 1)
                }
            }.onChange(of: item, initial: true) { oldValue, newValue in
                switch newValue.content {
                case .data(let data):
                    platformImage = .init(data: data)
                case .url(let url):
                    platformImage = .init(byReferencing: url)
                }
            }
        }
        
    }

}

/*
 
 
 ["public.jpeg", "public.png", "com.compuserve.gif", "com.canon.tif-raw-image", "com.adobe.raw-image", "com.dxo.raw-image", "com.canon.cr2-raw-image", "com.canon.cr3-raw-image", "com.leafamerica.raw-image", "com.hasselblad.fff-raw-image", "com.hasselblad.3fr-raw-image", "com.nikon.raw-image", "com.nikon.nrw-raw-image", "com.pentax.raw-image", "com.samsung.raw-image", "com.sony.raw-image", "com.sony.sr2-raw-image", "com.sony.arw-raw-image", "com.sony.axr-raw-image", "com.epson.raw-image", "com.kodak.raw-image", "public.tiff", "public.jpeg-2000", "com.apple.atx", "org.khronos.astc", "org.khronos.ktx", "org.khronos.ktx2", "public.avci", "public.jpeg-xl", "public.avif", "public.avis", "public.heic", "public.heics", "public.heif", "com.canon.crw-raw-image", "com.fuji.raw-image", "com.panasonic.raw-image", "com.panasonic.rw2-raw-image", "com.leica.raw-image", "com.leica.rwl-raw-image", "com.konicaminolta.raw-image", "com.olympus.sr-raw-image", "com.olympus.or-raw-image", "com.olympus.raw-image", "com.phaseone.raw-image", "com.microsoft.ico", "com.microsoft.bmp", "com.apple.icns", "com.adobe.photoshop-image", "com.microsoft.cur", "com.truevision.tga-image", "com.ilm.openexr-image", "org.webmproject.webp", "com.sgi.sgi-image", "public.radiance", "public.pbm", "public.mpo-image", "public.pvr", "com.microsoft.dds", "com.apple.pict"]
 
 
 ["public.jpeg", "public.png", "com.compuserve.gif", "public.tiff", "public.jpeg-2000", "com.apple.atx", "org.khronos.ktx", "org.khronos.ktx2", "org.khronos.astc", "com.microsoft.dds", "public.heic", "public.heics", "com.microsoft.ico", "com.microsoft.bmp", "com.apple.icns", "com.adobe.photoshop-image", "com.adobe.pdf", "com.truevision.tga-image", "com.ilm.openexr-image", "public.pbm", "public.pvr"]
 
 */

