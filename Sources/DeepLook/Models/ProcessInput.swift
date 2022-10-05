//  Copyright © 2019 la-labs. All rights reserved.

import Foundation
import UIKit
import Vision
import AVFoundation

protocol ProcessAssetsProtocol {
    var identifier: String { get }
    var image: UIImage { get }
}

/// Wrapper model for process configuration and asset
public struct ProcessInput {
  
  /// Process configuration contain configuration for each asset process.
  let configuration: ProcessConfiguration
  
  /// Asset itself.
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
  let text: [String]
  let imageBuffer: CVImageBuffer?

  init(identifier: String,
       image: UIImage,
       tags: [DetectedObject],
       boundingBoxes: [CGRect],
       faces: [Face],
       text: [String],
       imageBuffer: CVImageBuffer? = nil) {
    self.identifier = identifier
    self.image = image
    self.tags = tags
    self.normalizedBoundingBoxes = boundingBoxes
    self.faces = faces
    self.text = text
    self.imageBuffer = imageBuffer
  }

  init(identifier: String, image: UIImage) {
    self.init(identifier: identifier,
              image: image,
              tags: [],
              boundingBoxes: [],
              faces: [],
              text: [])
  }

  init(identifier: String,
       image: UIImage,
       faces: [Face]) {
    self.init(identifier: identifier,
              image: image,
              tags: [],
              boundingBoxes: [],
              faces: faces,
              text: [])
  }

  init(image: UIImage) {
    self.init(identifier: UUID().uuidString,
              image: image,
              tags: [],
              boundingBoxes: [],
              faces: [],
              text: [])
  }

  init(imageBuffer: CVImageBuffer) {
    self.init(
      identifier: UUID().uuidString,
      image: UIImage(),
      tags: [],
      boundingBoxes: [],
      faces: [],
      text: [],
      imageBuffer: imageBuffer)
  }
}

struct CustomProcessAsset: ProcessAssetsProtocol {
    let identifier: String
    let image: UIImage
}
