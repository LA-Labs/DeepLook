//  Copyright © 2019 la-labs. All rights reserved.

import Foundation

struct SamplePair<T: Comparable> {
    
    let index1: T
    let index2: T
    let distance: Double
    
    init(idx1: T, idx2: T, distance: Double = 1) {
        self.distance = distance
        if (idx1 < idx2) {
            index1 = idx1
            index2 = idx2
        } else {
            index1 = idx2
            index2 = idx1
        }
    }
}

struct OrderedSamplePair<T> {
    
    let index1: T
    let index2: T
    let distance: Double
    
    init(idx1: T, idx2: T, distance: Double = 1) {
        self.distance = distance
        index1 = idx1
        index2 = idx2
    }
}

struct Pair<T> {
    let index1: Int
    let index2: Int
    
    init(idx1: Int, idx2: Int) {
        index1 = idx1
        index2 = idx2
    }
}
