//
//  ProcessAsset.swift
//  
//
//  Created by Amir Lahav on 29/01/2021.
//  Copyright © 2019 la-labs. All rights reserved.

import Foundation
import UIKit
import Vision

protocol ProcessAssetsProtocol {
    var identifier: String { get }
    var image: UIImage { get }
}

/// Wrapper model for process configuration and asset
public struct ProcessInput {
    
    /// Process configuration contain configuration for each asset process.
    let configuration: ProcessConfiguration
    
    /// Asset it self.
    let asset: ProcessAsset
    
    init(asset: ProcessAsset,
         configuration: ProcessConfiguration = ProcessConfiguration()) {
        self.asset = asset
        self.configuration = configuration
    }
}

struct ProcessAsset: ProcessAssetsProtocol {
    let identifier: String
    let image: UIImage
    let tags: [DetectedObject]
    let normalizedBoundingBoxes: [CGRect]
    let faces: [Face]
    
    init(identifier: String,
         image: UIImage,
         tags: [DetectedObject],
         boundingBoxes: [CGRect],
         faces: [Face]) {
        self.identifier = identifier
        self.image = image
        self.tags = tags
        self.normalizedBoundingBoxes = boundingBoxes
        self.faces = faces
    }
    
    init(identifier: String, image: UIImage) {
        self.init(identifier: identifier,
                  image: image,
                  tags: [],
                  boundingBoxes: [],
                  faces: [])
    }
    
    init(identifier: String,
         image: UIImage,
         faces: [Face]) {
        self.init(identifier: identifier,
                  image: image,
                  tags: [],
                  boundingBoxes: [],
                  faces: faces)
    }
}

struct CustomProcessAsset: ProcessAssetsProtocol {
    let identifier: String
    let image: UIImage
}
