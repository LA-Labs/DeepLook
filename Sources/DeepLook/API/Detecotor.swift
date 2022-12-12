//  Copyright © 2019 la-labs. All rights reserved.

import Foundation
import UIKit

/// Reference to `LKDetector.default` for quick bootstrapping and examples.
@available(iOS 13.0, *)
public let Detector = LKDetector.default

@available (iOS 13.0, *)
public class LKDetector {

  // shared instance
  public static let `default` = LKDetector()

  // intimate only once.
  private init() { }

  //MARK: Public API
  /// Apply vision actions on user gallery photos.
  /// Action can be chained to preform multiple request
  /// like .objectDetection + .faceLocation.
  ///
  /// - Parameters:
  ///   - actions: Action request like face location, object detection, face landmarks
  ///   - options: Options for fetch asset from user galley.
  ///   Can be order and limited.
  ///   - processConfiguration: Configuration for action process, like model, image size etc.
  /// - Returns: Result contain list of ProcessOutput that contain all data requested.
  public func analyze(
    _ actions: ActionType<ProcessInput>,
    with options: AssetFetchingOptions,
    processConfiguration: ProcessConfiguration = ProcessConfiguration()
  ) async throws -> [ProcessOutput] {
      let assets = Vision.assetService.stackInputs(
        with: options,
        processConfiguration: processConfiguration
      )
      return try await Vision.detect(objects: assets, process: actions.process)
    }

  /// Apply vision actions on an image.
  /// Action can be chained to preform multiple request
  /// like .objectDetection + .faceLocation.
  ///
  /// - Parameters:
  ///   - actions: Action request to perform on source images like face location, object detection, face landmarks.
  ///   - sourceImage: Source image to perform on.
  ///   - processConfiguration: Configuration for action process, like model, image size etc.
  /// - Returns: Result contain list of ProcessOutput that contain all data requested.
  public func analyze(
    _ actions: ActionType<ProcessInput>,
    sourceImage: UIImage,
    processConfiguration: ProcessConfiguration = ProcessConfiguration()
  )  async throws -> [ProcessOutput] {
    try await analyze(actions, sourceImages: sourceImage,
                      processConfiguration: processConfiguration)
  }

  /// Apply computer vision actions on multiple provided images.
  /// Action can be chained to preform multiple request
  /// like .objectDetection + .faceLocation.
  ///
  /// - Parameters:
  ///   - actions: Action request to perform on source images like face location, object detection, face landmarks.
  ///   - sourceImages: Source images to perform on.
  ///   - processConfiguration: Configuration for action process, like model, image size etc.
  /// - Returns: Result contain list of ProcessOutput that contain all data requested.
  public func analyze(
    _ actions: ActionType<ProcessInput>,
    sourceImages: UIImage...,
    processConfiguration: ProcessConfiguration = ProcessConfiguration()
  ) async throws -> [ProcessOutput] {
    try await analyze(actions, sourceImages: sourceImages,
                      processConfiguration: processConfiguration)
  }

  public func faceLocations(
    in sourceImages: UIImage...,
    processConfiguration: ProcessConfiguration = ProcessConfiguration()
  ) async throws -> [ProcessOutput] {
    try await analyze(.faceLocation,
                      sourceImages: sourceImages,
                      processConfiguration: processConfiguration)
  }

  public func objectLocations(
    in sourceImages: UIImage...,
    processConfiguration: ProcessConfiguration = ProcessConfiguration()
  ) async throws -> [ProcessOutput] {
    try await analyze(.objectLocation,
                      sourceImages: sourceImages,
                      processConfiguration: processConfiguration)
  }
}

@available (iOS 13.0, *)
private extension LKDetector {

  func analyze(
    _ actions: ActionType<ProcessInput>,
    sourceImages: [UIImage],
    processConfiguration: ProcessConfiguration = ProcessConfiguration()
  ) async throws -> [ProcessOutput] {
    let inputAsset = sourceImages.map { (sourceImage) in
      ProcessAsset(identifier: "sourceImage", image: sourceImage)
    }.map { (processAsset) in
      ProcessInput(asset: processAsset, configuration: processConfiguration)
    }.chunked(into: 10)
    var objects = Stack<[ProcessInput]>()
    inputAsset.forEach { (chunk) in
      objects.push(chunk)
    }
    return try await Vision.detect(objects: objects, process: actions.process)
  }
}
