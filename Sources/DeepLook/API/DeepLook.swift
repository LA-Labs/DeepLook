//  Copyright © 2019 la-labs. All rights reserved.

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

  /// Given an image, returns an array of texts describing objects in the image.
  ///
  /// - Parameters:
  ///   - image: The image that contains one or more objects.
  ///   - processConfiguration: Allow fine tuning process configuration.
  /// - Returns: A sorted list by probability of classified object.
  public func imageClassification(
    _ faceImage: UIImage,
    processConfiguration: ProcessConfiguration = ProcessConfiguration()
  ) -> [String] {
    let input = ProcessInput(
      asset: ProcessAsset(image: faceImage),
      configuration: processConfiguration
    )

    return Processor
      .singleInputProcessor(element: input, preformOn: Actions.objectDetecting)
      .asset.tags.map(\.identifier)
  }

  /// Given an image, return the Multi-dimension face encoding for each face in the image.
  ///
  /// - Parameters:
  ///   - faceImage: The image that contains one or more faces.
  ///   - knownFaceLocations: Optional - the bounding boxes of each face if you already know them.
  ///   - model: Which model to use.
  ///   - processConfiguration: Allow fine tuning process configuration.
  /// - Returns: A list of Multi-dimensional face encodings (one for each face in the image).
  public func faceEncodings(
    _ faceImage: UIImage,
    knownFaceLocations: [CGRect] = [],
    model: ProcessConfiguration.FaceEncoderModel = .facenet,
    processConfiguration: ProcessConfiguration = ProcessConfiguration()
  ) -> [[Double]] {
    processConfiguration.faceEncoderModel = model

    switch model {
    case .facenet:
      processConfiguration.faceChipSize = 160
    case .VGGFace2_resnet_Lite,
        .VGGFace2_senet_Lite:
      processConfiguration.faceChipSize = 224
    }

    let faces = knownFaceLocations.map {
      Face(faceObservation: VNFaceObservation(boundingBox: $0))
    }

    let asset = ProcessAsset(
      identifier: UUID().uuidString,
      image: faceImage,
      faces: faces
    )

    let input = ProcessInput(
      asset: asset,
      configuration: processConfiguration
    )

    let encoding = Processor
      .singleInputProcessor(
        element: input,
        preformOn: ActionType<ProcessInput>.faceEncoding.process
      )
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
  ///   - processConfiguration: Allow fine tuning process configuration.
  /// - Returns: A list of `VNFaceLandmarks2D` of face feature locations (eyes, nose, etc)
  public func faceLandmarks(
    _ faceImage: UIImage,
    knownFaceLocations: [CGRect] = [],
    processConfiguration: ProcessConfiguration = ProcessConfiguration()
  ) -> [VNFaceLandmarkRegion2D] {

    let faces = knownFaceLocations.map {
      Face(faceObservation: VNFaceObservation(boundingBox: $0))
    }

    let asset = ProcessAsset(
      identifier: "id",
      image: faceImage,
      faces: faces
    )

    let input = ProcessInput(
      asset: asset,
      configuration: processConfiguration
    )

    let landmarks = Processor
      .singleInputProcessor(element: input, preformOn: ActionType<ProcessInput>.faceEncoding.process)
      .asset.faces
      .compactMap { $0.landmarks?.allPoints }
    return landmarks
  }

  /// Given an image, returns an array of bounding boxes of human faces in an image.
  ///
  /// - Parameters:
  ///   - faceImage: The image that contains one or more faces.
  ///   - processConfiguration: Allow fine tuning process configuration.
  /// - Returns: A list of found face normalized locations. Bottom - Left coordinate system.
  public func faceLocation(
    _ faceImage: UIImage,
    processConfiguration: ProcessConfiguration = ProcessConfiguration()
  ) -> [CGRect] {
    let input = ProcessInput(
      asset: ProcessAsset(image: faceImage),
      configuration: processConfiguration
    )

    return Processor
      .singleInputProcessor(element: input, preformOn: Actions.faceLocation)
      .asset.normalizedBoundingBoxes
  }

  /// Returns an array of bounding boxes of human faces in an image.
  ///
  /// - Parameters:
  ///   - faceImage: The image that contains one or more faces.
  ///   - processConfiguration: Allow fine tuning process configuration.
  /// - Returns: A list of found face normalized locations. Bottom - Left coordinate system.
  public func videoFaceLocation(
    _ faceImage: CVImageBuffer,
    processConfiguration: ProcessConfiguration = ProcessConfiguration()
  ) -> [CGRect] {
    precondition (!Thread.isMainThread, "Do not run on main thread.")
    let input = ProcessInput(
      asset: ProcessAsset(imageBuffer: faceImage),
      configuration: processConfiguration
    )

    return Processor
      .singleInputProcessor(element: input, preformOn: Actions.videoFaceRectangle)
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
  ///   - knownFaceLocations: Optional - the bounding boxes of each face if you
  ///    already know them.
  ///   - processConfiguration: Allow fine tuning process configuration.
  /// - Returns: List of emotion recognize for each face in the image.
  public func faceEmotion(
    _ faceImage: UIImage,
    knownFaceLocations: [CGRect] = [],
    processConfiguration: ProcessConfiguration = ProcessConfiguration()
  ) -> [Face.FaceEmotion] {
    let action = ActionType<ProcessInput>.faceEmotion.process
    let faces = knownFaceLocations.map { (location) -> Face in
      Face(
        faceObservation: VNFaceObservation(boundingBox: location)
      )
    }

    let asset = ProcessAsset(
      identifier: UUID().uuidString,
      image: faceImage,
      faces: faces
    )
    let input = ProcessInput(asset: asset,
                             configuration: processConfiguration)

    let landmarks = Processor
      .singleInputProcessor(element: input,
                            preformOn: action)
      .asset.faces
      .compactMap { $0.faceEmotion }
    return landmarks
  }

  /// An image analysis request that finds and recognizes text in an image.
  ///
  /// - Parameters:
  ///   - image: The image contain text.
  ///   - processConfiguration: Allow fine tuning process configuration.
  /// - Returns: List of detected texts.
  public func textRecognition(
    _ image: UIImage,
    textRecognitionLevel: VNRequestTextRecognitionLevel = .fast,
    usesLanguageCorrection: Bool = false,
    processConfiguration: ProcessConfiguration = ProcessConfiguration()
  ) -> [String] {
    let asset = ProcessInput(
      asset: ProcessAsset(identifier: UUID().uuidString, image: image),
      configuration: processConfiguration
    )
    processConfiguration.textRecognitionLevel = textRecognitionLevel
    processConfiguration.usesLanguageCorrection = usesLanguageCorrection

    return Processor
      .singleInputProcessor(
        element: asset,
        preformOn: Actions.textRecognition
      ).asset.text
  }

  /// An image analysis request that finds and recognizes text in an image.
  ///
  /// - Parameters:
  ///   - imageBuffer: The buffer contain text.
  ///   - processConfiguration: Allow fine tuning process configuration.
  /// - Returns: List of detected texts.
  public func videoTextRecognition(
    _ imageBuffer: CVImageBuffer,
    usesLanguageCorrection: Bool = false,
    processConfiguration: ProcessConfiguration = ProcessConfiguration()
  ) -> [String] {
    precondition (!Thread.isMainThread, "Do not run on main thread.")
    processConfiguration.usesLanguageCorrection = usesLanguageCorrection

    let asset = ProcessInput(
      asset: ProcessAsset(imageBuffer: imageBuffer),
      configuration: processConfiguration
    )
    return Processor
      .singleInputProcessor(
        element: asset,
        preformOn: ActionType<ProcessInput>
          .videoTextRecognition
          .process
      ).asset.text
  }
}
