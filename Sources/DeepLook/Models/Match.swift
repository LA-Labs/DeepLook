//
//  Match.swift
//  LookKit
//
//  Created by Amir Lahav on 18/03/2021.
//

import Foundation

/// Match faces data model.
public struct Match {
    
    /// Face detected in the source image.
    public let sourceFace: Face
    
    /// Match face detected in the target image.
    public let targetFace: Face
    
    /// The distance between 2 founded faces.
    public let distance: Double
    
    /// Maximum threshold set by the user.
    public let threshold: Double
}
