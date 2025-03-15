//
//  ImageDropError.swift
//  AnimatedImageConverter
//
//  Created by 박병관 on 3/15/25.
//

import Foundation


struct ImageDropError:LocalizedError {
    
    
    var innerError:any Error
    
    var errorDescription: String? {
        innerError.localizedDescription
    }
    

    
    
}
