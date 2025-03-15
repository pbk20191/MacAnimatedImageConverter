//
//  ItemWrapperIdentifier.swift
//  AnimatedImageConverter
//
//  Created by 박병관 on 3/15/25.
//

import Foundation

struct ItemWrapperIdentifier: Identifiable {
    var id = UUID()
    var item:AnimatedImageImportable
}
