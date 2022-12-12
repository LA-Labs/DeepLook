//  Copyright © 2019 la-labs. All rights reserved.

import Foundation
import UIKit

/// Reference to `LKImageProcessor.default` for quick bootstrapping and examples.
@available (iOS 13.0, *)
public let ImageProcessor = LKImageProcessor.default

@available (iOS 13.0, *)
public class LKImageProcessor {

  // shared instance
  public static let `default` = LKImageProcessor()

  // initiate only once.
  private init() { }

  public func alignFaces(in sourceImages: UIImage...,
                         processConfiguration: ProcessConfiguration = ProcessConfiguration()
  ) async throws -> [Face] {
    try await alignFaces(
      sourceImages: sourceImages,
      processConfiguration: processConfiguration)
  }

  public func alignFaces(sourceImages: [UIImage],
                         processConfiguration: ProcessConfiguration = ProcessConfiguration()
  ) async throws -> [Face] {
    precondition(!sourceImages.isEmpty, "sourceImages must not be empty")
    let featureDetecting = Actions.cropAndAlignFaces
    let input = sourceImages.map { (sourceImage) in
      ProcessAsset(identifier: "sourceImage", image: sourceImage)
    }.map { (processAsset) -> ProcessInput in
      ProcessInput(asset: processAsset, configuration: processConfiguration)
    }.chunked(into: 10)
    var objects = Stack<[ProcessInput]>()
    input.forEach { (inputs) in
      objects.push(inputs)
    }
    let photos = try await Vision.detect(objects: objects, process: featureDetecting)
    let faces = photos.map { (asset) -> [Face] in
      asset.faces
    }.flatMap({$0})
    return faces
  }


  public func alignFaces(fetchOptions: AssetFetchingOptions,
                         processConfiguration: ProcessConfiguration
  ) async throws -> [Face] {
    let featureDetecting = Actions.cropAndAlignFaces
    let assets = Vision.assetService.stackInputs(with: fetchOptions,
                                                 processConfiguration: processConfiguration)
    let photos = try await Vision.detect(
      objects: assets,
      process: featureDetecting
    )
    let faces = photos.map { (asset) -> [Face] in
      asset.faces
    }.flatMap({$0})
    return faces
  }
}
