//
//  CGSize + Extension.swift
//  DeepLook
//
//  Created by Amir Lahav on 17/02/2021.
//  Copyright © 2019 la-labs. All rights reserved.

#if os(OSX)
import AppKit
#elseif os(iOS)
import UIKit
#endif

extension CGSize {
    func scale(imageSize: CGSize) -> CGSize {
        CGSize(width: width * imageSize.width, height: height * imageSize.height)
    }
    
    var area: CGFloat {
        width * height
    }
}
