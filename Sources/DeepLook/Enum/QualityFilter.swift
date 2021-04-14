//
//  QualityFilter.swift
//  LookKit
//
//  Created by Amir Lahav on 24/02/2021.
//  Copyright © 2019 la-labs. All rights reserved.

import Foundation

/// Face Quality Filter
/// in range of [0,1].
/// Higher is better
public enum QualityFilter {
    /// 0
    case none
    /// 0.1
    case low
    /// 0.25
    case medium
    /// 0.35
    case high
    /// 0.4
    case extreme
    
    var value: Float {
        switch self {
        case .none:
            return 0
        case .low:
            return 0.1
        case .medium:
            return 0.25
        case .high:
            return 0.35
        case .extreme:
            return  0.4
        }
    }
}
