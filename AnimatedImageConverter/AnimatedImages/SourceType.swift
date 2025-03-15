//
//  SourceType.swift
//  AnimateImageData
//
//  Created by 박병관 on 3/14/25.
//  Copyright © 2025 Augmented Code. All rights reserved.
//

import Foundation

enum DataSourceType:Hashable {
    case data(Data)
    case url(URL)
}
