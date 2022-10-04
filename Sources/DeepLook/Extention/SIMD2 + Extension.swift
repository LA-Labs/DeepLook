//
//  SIMD2 + Extension.swift
//  DeepLook
//
//  Created by Amir Lahav on 13/02/2021.
//  Copyright © 2019 la-labs. All rights reserved.

import simd
#if os(OSX)
import AppKit
#elseif os(iOS)
import UIKit
#endif

extension SIMD2 where Scalar == Double {
    func apply(_ transform: CGAffineTransform) -> simd_double2 {
        let point = CGPoint(x: self.x, y: self.x)
        point.applying(transform)
        return simd_double2(Double(point.x), Double(point.y))
    }
    
    var length: Double {
        sqrt(pow(x, 2) + pow(y, 2))
    }
}

extension simd_double2 {
    func toPoint() -> CGPoint {
        CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
}
