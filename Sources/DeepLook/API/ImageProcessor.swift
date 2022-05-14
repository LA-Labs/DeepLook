//
//  ImageProcessor.swift
//  LookKit
//
//  Created by Amir Lahav on 27/02/2021.
//  Copyright © 2019 la-labs. All rights reserved.

import Foundation
#if os(OSX)
import AppKit
#elseif os(iOS)
import UIKit
#endif

/// Reference to `LKImageProcessor.default` for quick bootstrapping and examples.
public let ImageProcessor = LKImageProcessor.default

public class LKImageProcessor {

  // shared instance
  public static let `default` = LKImageProcessor()

  // initiate only once.
  private init() { }

  public func alignFaces(in sourceImages: UIImage...,
                         processConfiguration: ProcessConfiguration = ProcessConfiguration(),
                         completion: @escaping (Result<[Face], VisionProcessError>) -> Void) {
    alignFaces(
      sourceImages: sourceImages,
      processConfiguration: processConfiguration,
      completion: completion
    )
  }

  public func alignFaces(sourceImages: [UIImage],
                         processConfiguration: ProcessConfiguration = ProcessConfiguration(),
                         completion: @escaping (Result<[Face], VisionProcessError>) -> Void) {
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
    Vision.detect(objects: objects, process: featureDetecting) { (result) in
      switch result {
      case .success(let photos):
        let faces = photos.map { (asset) -> [Face] in
          asset.faces
        }.flatMap({$0})
        completion(.success(faces))
      case .failure(let error):
        print(error)
      }
    }
  }


  public func alignFaces(fetchOptions: AssetFetchingOptions,
                         processConfiguration: ProcessConfiguration,
                         completion: @escaping (Result<[Face], VisionProcessError>) -> Void) {
    let featureDetecting = Actions.cropAndAlignFaces
    let assets = Vision.assetService.stackInputs(with: fetchOptions,
                                                 processConfiguration: processConfiguration)
    Vision.detect(objects: assets, process: featureDetecting) { (result) in
      switch result {
      case .success(let photos):
        let faces = photos.map { (asset) -> [Face] in
          asset.faces
        }.flatMap({$0})
        completion(.success(faces))
      case .failure(let error):
        print(error)
      }
    }
  }
}
