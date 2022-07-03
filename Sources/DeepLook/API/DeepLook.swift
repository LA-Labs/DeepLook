//
//  DeepLook.swift
//  DeepLook
//
//  Created by Amir Lahav on 31/03/2021.
//

import Foundation
import UIKit
import Vision

/// Reference to `LKRecognition.default` for quick bootstrapping and examples.
public let DeepLook = LKDeepLook.default

public class LKDeepLook {

  /// shared instance.
  public static let `default` = LKDeepLook()

  // initiate only once.
  private init() { }


  /// Given an image, return the Multi-dimension face encoding for each face in the image.
  ///
  /// - Parameters:
  ///   - faceImage: The image that contains one or more faces.
  ///   - knownFaceLocations: Optional - the bounding boxes of each face if you already know them.
  ///   - model: which model to use.
  /// - Returns: A list of Multi-dimensional face encodings (one for each face in the image).
  public func faceEncodings(
    _ faceImage: UIImage,
    knownFaceLocations: [CGRect] = [],
    model: ProcessConfiguration.FaceEncoderModel = .facenet
  ) async -> [[Double]] {
    let config = ProcessConfiguration()
    config.faceEncoderModel = model

    switch model {
    case .facenet:
      config.faceChipSize = 160
    case .VGGFace2_resnet_Lite,
        .VGGFace2_senet_Lite:
      config.faceChipSize = 224
    }

    let faces = knownFaceLocations.map { (location) -> Face in
      Face(localIdentifier: "id", faceCroppedImage: UIImage(),
           faceObservation: VNFaceObservation(boundingBox: location),
           quality: 0,
           roll: 0,
           faceEncoding: [],
           faceEmotion: .none)
    }

    let asset = ProcessAsset(identifier: "id",
                             image: faceImage,
                             faces: faces)

    let input = ProcessInput(asset: asset,
                             configuration: config)
    let encoding = await Processor
      .singleInputProcessor(element: input, preformOn: ActionType.faceEncoding.process)
      .asset.faces
      .map { (face) -> [Double] in
        face.faceEncoding
      }
    return encoding
  }

  /// Given an image, returns a `VNFaceLandmarks2D` of face feature locations
  /// (eyes, nose, etc) for each face in the image.
  ///
  /// - Parameters:
  ///   - faceImage: The image that contains one or more faces.
  ///   - knownFaceLocations: Optional - the bounding boxes of each face if you already know them.
  /// - Returns: A list of `VNFaceLandmarks2D` of face feature locations (eyes, nose, etc)
  public func faceLandmarks(
    _ faceImage: UIImage,
    knownFaceLocations: [CGRect] = []
  ) async -> [VNFaceLandmarkRegion2D] {
    let config = ProcessConfiguration()
    config.minimumFaceArea = 0

    let faces = knownFaceLocations.map { (location) -> Face in
      Face(localIdentifier: "id",
           faceCroppedImage: UIImage(),
           faceObservation: VNFaceObservation(boundingBox: location),
           quality: 0,
           roll: 0,
           faceEncoding: [],
           faceEmotion: .none)
    }

    let asset = ProcessAsset(identifier: "id",
                             image: faceImage,
                             faces: faces)

    let input = ProcessInput(asset: asset,
                             configuration: config)

    let landmarks = await Processor
      .singleInputProcessor(element: input, preformOn: ActionType.faceEncoding.process)
      .asset.faces
      .compactMap { $0.landmarks?.allPoints }
    return landmarks
  }

  /// Returns an array of bounding boxes of human faces in an image.
  ///
  /// - Parameter faceImage: The image that contains one or more faces.
  /// - Returns: A list of found face normalized locations. Bottom - Left coordinate system.
  public func faceLocation(_ faceImage: UIImage) async -> [CGRect] {
    let input = ProcessInput(
      asset: ProcessAsset(identifier: "id",
                          image: faceImage),
      configuration: ProcessConfiguration()
    )

    return await Processor
      .singleInputProcessor(element: input, preformOn: Actions.faceLocation)
      .asset.normalizedBoundingBoxes
  }

  /// Given a list of face encodings, compare them to a known face encoding and get a euclidean
  /// distance for each comparison face. The distance tells you how similar the faces are.
  ///
  /// - Parameters:
  ///   - faceEncodings: List of face encodings to compare.
  ///   - faceToCompare:  A face encoding to compare against.
  /// - Returns: An array with the distance for each face in the same order as the ‘faces’ array
  public func faceDistance(_ faceEncodings: [[Double]], faceToCompare: [Double]) -> [Double] {
    faceEncodings.map({ faceDistance(faceEncodings: $0, faceToCompare: faceToCompare) })
  }

  /// Compare a list of face encodings against a candidate encoding to see if they match.
  ///
  /// - Parameters:
  ///   - faceEncodings: List of face encodings to compare.
  ///   - faceToCompare:  A face encoding to compare against.
  ///   - threshold: How much distance between faces to consider it a match.
  ///   Lower is more strict. 0.6 is typical best performance.
  /// - Returns: A list of True/False values indicating which `faceEncodings`
  /// match the face encoding to check
  public func compareFaces(
    _ faceEncodings: [[Double]],
    faceToCompare: [Double],
    threshold: Double = 0.6
  ) -> [Bool] {
    faceDistance(faceEncodings, faceToCompare: faceToCompare).map({$0 <= threshold})
  }

  private func faceDistance(faceEncodings: [Double], faceToCompare: [Double]) -> Double {
    var sum: Double = 0
    for i in 0...faceEncodings.count-1 {
      sum += (pow(faceEncodings[i] - faceToCompare[i], 2))
    }
    return sqrt(sum)
  }

  /// Crop faces chip based on face location result.
  ///
  /// After you got face locations you might want to crop faces to chips.
  /// - Parameters:
  ///   - faceImage: The image that contains one or more faces.
  ///   - locations: Optional - the bounding boxes of each face if you already know them.
  /// - Returns: List of crop chip faces.
  public func cropFaces(_ faceImage: UIImage, locations: [CGRect]) -> [UIImage] {
    locations.compactMap { (boundingBox) in

      guard let cgImage = faceImage.cgImage else {
        return nil
      }
      let width = boundingBox.width * CGFloat(cgImage.width)
      let height = boundingBox.height * CGFloat(cgImage.height)
      let x = boundingBox.origin.x * CGFloat(cgImage.width)
      let y = (1 - boundingBox.origin.y) * CGFloat(cgImage.height) - height

      let croppingRect = CGRect(x: x, y: y, width: width, height: height)
      guard let croppedCgImage = cgImage.cropping(to: croppingRect) else {
        return nil
      }
      return UIImage(cgImage: croppedCgImage)
    }
  }

  /// Given an image, returns a `FaceEmotion` (such as happy, sad, angry)
  /// for each face in the image.
  ///
  /// - Parameters:
  ///   - faceImage: The image that contains one or more faces.
  ///   - knownFaceLocations: Optional - the bounding boxes of each face if you already know them.
  /// - Returns: List of emotion recognize for each face in the image.
  public func faceEmotion(
    _ faceImage: UIImage,
    knownFaceLocations: [CGRect] = []
  ) async -> [Face.FaceEmotion] {

    let action = ActionType.faceEmotion.process
    let config = ProcessConfiguration()
    config.minimumFaceArea = 0
    let faces = knownFaceLocations.map { (location) -> Face in
      Face(localIdentifier: "id",
           faceCroppedImage: UIImage(),
           faceObservation: VNFaceObservation(boundingBox: location),
           quality: 0,
           roll: 0,
           faceEncoding: [],
           faceEmotion: .none)
    }
    let asset = ProcessAsset(identifier: "id",
                             image: faceImage,
                             faces: faces)
    let input = ProcessInput(asset: asset,
                             configuration: config)

    let landmarks = await Processor
      .singleInputProcessor(element: input,
                            preformOn: action)
      .asset.faces
      .compactMap { $0.faceEmotion }
    return landmarks
  }
}
