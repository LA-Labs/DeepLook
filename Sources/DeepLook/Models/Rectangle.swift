//  Copyright © 2019 la-labs. All rights reserved.

import UIKit
import simd

class Rectangle {
    let top: Double
    let right: Double
    let bottom: Double
    let left: Double
    
    var topLeft: simd_double2 {
        simd_double2(left, top)
    }
    
    var rect: CGRect {
        CGRect(origin: topLeft.toPoint(),
               size: CGSize(width: width, height: height))
    }
    
    var width: Double {
        right - left + 1
    }
    
    var height: Double {
        bottom - top + 1
    }
    
    var area: Double {
        width * height
    }
    
    var isEmpty: Bool {
        top > bottom || left > right
    }
    
    var size: CGSize {
        CGSize(width: width, height: height)
    }
    
    init(left: Double,
         top: Double,
         right: Double,
         bottom: Double) {
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left
    }
    
    static func +(lhs: Rectangle, rhs: Rectangle) -> Rectangle {
        Rectangle(left: min(lhs.left, rhs.left),
                   top: min(lhs.top, rhs.top),
                   right: max(rhs.right, lhs.right),
                   bottom: max(rhs.bottom, lhs.bottom))
    }
}


class CenteredDrect: Rectangle {
    convenience init(point: simd_double2,
         width: Double,
         height: Double) {
         self.init(left: point.x-width/2,
                  top: point.y-height/2,
                  right: point.x+width/2,
                  bottom: point.y+height/2)
    }
}
