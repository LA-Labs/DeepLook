//
//  CGPoint + Extension.swift
//  DeepLook
//
//  Created by Amir Lahav on 13/02/2021.
//  Copyright © 2019 la-labs. All rights reserved.

#if os(OSX)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import simd

extension CGPoint {
    func toVector() -> simd_double2 {
        simd_double2(Double(x), Double(y))
    }
    
    static func /(_ rhs: CGPoint, magnitude: CGFloat) -> CGPoint {
        CGPoint(x: rhs.x/magnitude, y: rhs.y/magnitude)
    }
    
    static func +(_ rhs: CGPoint, magnitude: CGFloat) -> CGPoint {
        CGPoint(x: rhs.x + magnitude, y: rhs.y + magnitude)
    }
}
