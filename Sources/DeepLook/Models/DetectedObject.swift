//
//  DetectedObject.swift
//  DeepLook
//
//  Created by Amir Lahav on 25/02/2021.
//  Copyright © 2019 la-labs. All rights reserved.

import Foundation
import UIKit

public struct DetectedObject: Equatable {
    /// Identified class
    public let identifier: String
    
    /// Confidence in identified class
    public let confidence: Float
    
    /// Normalized object location
    public let normalizedLocation: CGRect
}
