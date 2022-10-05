//  Copyright © 2019 la-labs. All rights reserved.

import simd
import UIKit

class PointTransformAffine {
    var m: simd_double2x2
    var b: simd_double2
    
    init(m: simd_double2x2, b: simd_double2) {
        self.m = m
        self.b = b
    }
    
    func applyTransform(_ point: simd_double2) -> simd_double2 {
        let r = m * point + b
        return simd_double2(r.x, r.y)
    }
}
