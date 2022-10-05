//  Created by amir lahav on 10/11/2019.
//  Copyright © 2019 la-labs. All rights reserved.

import Foundation
import Vision
import CoreML
import DeepLookModels
import UIKit
import AVFoundation


public typealias Action = (ProcessInput)  throws -> ProcessInput
typealias JobPipeline = (ProcessInput) throws -> ProcessOutput
typealias CustomFilter<T> = (ProcessInput) throws -> T

/// Reference to `LKActions.default` for quick bootstrapping and examples.
public let Actions = LKActions.default

public class LKActions {
  
  /// Models
  lazy var faceNet: VNCoreMLModel? = try? Models.getModel(by: .faceNet)
  lazy var vggResnet: VNCoreMLModel? = try? Models.getModel(by: .VGGFace2_resnet)
  lazy var vggSenet: VNCoreMLModel? = try? Models.getModel(by: .VGGFace2_senet)
  
  
  /// shared instance
  public static let `default` = LKActions()
  
  // initiate only once.
  private init() { }
  //MARK: Public
  
  /// An image analysis request that finds faces within an image.
  var faceLocation: Action {
    faceRectangle
  }
  
  /// A request to locate objects in an image.
  /// Objects include 100 different classes.
  var objectLocation: Action {
    objectLocationDetection
  }
  
  /// A request to classify an image.
  /// Objects include 1000 different classes.
  var objectDetecting: Action {
    tagPhoto
  }
  
  /// A request that produces a floating-point number representing the capture quality of a given face in a photo.
  var faceQuality: Action {
    imageQuality
  }
  
  /// An image analysis request that finds facial features (such as the eyes and mouth) in an image.
  var faceLandmarks: Action {
    featureDetection
  }
  
  /// An image analysis request that finds facial features crop and align the face in an image.
  var cropAndAlignFaces: Action {
    featureDetection >>> cropChipFaces
  }
  
  /// An image encoding request that encode facial features to floating-point vector.
  var faceEncoding: Action {
    cropAndAlignFaces >>> encodeFaces
  }
  
  /// An image analysis request that finds facial emotion (such as happy and angry) in an image.
  var faceEmotion: Action {
    cropAndAlignFaces >>> faceEmotionProcess
  }
  
  //MARK: Internal
  func fetchAsset() -> Action {
    fetchAsset
  }
  
  /// Detect bounding box around faces in image
  ///
  /// - Parameter asset: User image
  ///
  /// - Returns: ImageObservation struct include vision bounding rect, original image, and image size
  private func faceRectangle(input: ProcessInput) throws -> ProcessInput {
    
    precondition(input.asset.image.cgImage != nil, "must provide cgImage \(input.asset.identifier)")
    
    let requestHandler = VNImageRequestHandler(cgImage: (input.asset.image.cgImage!), options: [:])
    let request = VNDetectFaceRectanglesRequest()
    
#if targetEnvironment(simulator)
    request.usesCPUOnly = true
#endif
    try requestHandler.perform([request])
    guard let observations = request.results else {
      throw VisionProcessError.facesDetecting
    }
    let asset = ProcessAsset(identifier: input.asset.identifier,
                             image: input.asset.image,
                             tags: input.asset.tags,
                             boundingBoxes: boundingBoxToRects(observation: observations),
                             faces: input.asset.faces,
                             text: input.asset.text)
    return ProcessInput(asset: asset, configuration: input.configuration)
  }
  
  public func videoFaceRectangle(input: ProcessInput) throws -> ProcessInput {
    
    precondition(input.asset.imageBuffer != nil, "must provide CVPixelBuffer")
    
    let requestHandler = VNImageRequestHandler(cvPixelBuffer: input.asset.imageBuffer!, options: [:])
    let request = VNDetectFaceRectanglesRequest()
    
#if targetEnvironment(simulator)
    request.usesCPUOnly = true
#endif
    try requestHandler.perform([request])
    guard let observations = request.results else {
      throw VisionProcessError.facesDetecting
    }
    let asset = ProcessAsset(identifier: input.asset.identifier,
                             image: input.asset.image,
                             tags: input.asset.tags,
                             boundingBoxes: boundingBoxToRects(observation: observations),
                             faces: input.asset.faces,
                             text: input.asset.text)
    return ProcessInput(asset: asset, configuration: input.configuration)
  }
  
  
  public func textRecognition(
    input: ProcessInput
  ) throws -> ProcessInput {
    let textRequest = VNRecognizeTextRequest()
    
    // Configure for running in real-time.
    textRequest.recognitionLevel = input.configuration.textRecognitionLevel
    // Language correction won't help recognizing phone numbers. It also
    // makes recognition slower.
    textRequest.usesLanguageCorrection = input.configuration.usesLanguageCorrection
    // Only run on the region of interest for maximum speed.
    textRequest.regionOfInterest = input.configuration.roi
    
    let requestHandler = VNImageRequestHandler(cgImage: input.asset.image.cgImage!,
                                               orientation: .up,
                                               options: [:])
    try requestHandler.perform([textRequest])
    
    let result = textRequest.results!.compactMap { observation in
      // Return the string of the top VNRecognizedText instance.
      observation.topCandidates(1).first?.string
    }
    
    return ProcessInput(
      asset: .init(
        identifier: input.asset.identifier,
        image: input.asset.image,
        tags: input.asset.tags,
        boundingBoxes: input.asset.normalizedBoundingBoxes,
        faces: input.asset.faces,
        text: result,
        imageBuffer: input.asset.imageBuffer
      ),
      configuration: input.configuration
    )
  }
  
  public func videoTextRecognition(
    input: ProcessInput
  ) throws -> ProcessInput {
    let textRequest = VNRecognizeTextRequest()
    
    textRequest.recognitionLevel = input.configuration.textRecognitionLevel
    textRequest.usesLanguageCorrection =  input.configuration.usesLanguageCorrection
    textRequest.regionOfInterest = input.configuration.roi

    let requestHandler = VNImageRequestHandler(cvPixelBuffer: input.asset.imageBuffer!,
                                               orientation: .up,
                                               options: [:])
    try requestHandler.perform([textRequest])

    guard let result = textRequest.results else {
      return input
    }
    let texts: [String] = result.compactMap { visionResult in
      visionResult.topCandidates(1).first?.string
    }
    
    return ProcessInput(
      asset: .init(
        identifier: input.asset.identifier,
        image: input.asset.image,
        tags: input.asset.tags,
        boundingBoxes: input.asset.normalizedBoundingBoxes,
        faces: input.asset.faces,
        text: texts,
        imageBuffer: input.asset.imageBuffer
      ),
      configuration: input.configuration
    )
  }
  
  private func featureDetection(input: ProcessInput) throws -> ProcessInput {
    precondition(input.asset.image.cgImage != nil, "must provide cgImage \(input.asset.identifier)")
    let requestHandler = VNImageRequestHandler(cgImage: (input.asset.image.cgImage!), options: [:])
    let request = VNDetectFaceLandmarksRequest()
#if targetEnvironment(simulator)
    request.usesCPUOnly = true
#endif
    if !input.asset.faces.isEmpty {
      request.inputFaceObservations = input.asset.faces.map({ $0.faceObservation  })
    }
    try requestHandler.perform([request])
    guard let observations = request.results else {
      throw VisionProcessError.facesDetecting
    }
    
    guard observations.count == input.asset.faces.count else {
      
      let faces = observations.compactMap { (observation) -> Face? in
        guard hasMinimumLandmarkRequirement(observation: observation, input: input) else {
          return nil
        }
        return Face(localIdentifier: input.asset.identifier,
                    faceCroppedImage: UIImage(),
                    faceObservation: observation,
                    quality: 0,
                    roll: 0,
                    faceEncoding: [],
                    faceEmotion: .none)
      }
      
      let asset = ProcessAsset(identifier: input.asset.identifier,
                               image: input.asset.image,
                               tags: input.asset.tags,
                               boundingBoxes: boundingBoxToRects(observation: observations),
                               faces: faces,
                               text: input.asset.text)
      return ProcessInput(asset: asset, configuration: input.configuration)
    }
    
    
    let faces = zip(input.asset.faces, observations).compactMap { (face, observation) -> Face? in
      guard hasMinimumLandmarkRequirement(observation: observation, input: input) else {
        return nil
      }
      return Face(localIdentifier: face.localIdentifier,
                  faceCroppedImage: face.faceCroppedImage,
                  faceObservation: observation,
                  quality: face.quality,
                  roll: face.roll,
                  faceEncoding: face.faceEncoding,
                  faceEmotion: face.faceEmotion)
    }
    
    let asset = ProcessAsset(identifier: input.asset.identifier,
                             image: input.asset.image,
                             tags: input.asset.tags,
                             boundingBoxes: boundingBoxToRects(observation: observations),
                             faces: faces,
                             text: input.asset.text)
    return ProcessInput(asset: asset, configuration: input.configuration)
  }
  
  private func encodeFaces(input: ProcessInput) throws -> ProcessInput {
    var model: VNCoreMLModel?
    switch input.configuration.faceEncoderModel {
    case .facenet:
      model = faceNet
    case .VGGFace2_resnet_Lite:
      model = vggResnet
    case .VGGFace2_senet_Lite:
      model = vggSenet
    }
    
    guard let mlModel = model else {
      return input
    }
    let request = VNCoreMLRequest(model: mlModel)
#if targetEnvironment(simulator)
    request.usesCPUOnly = true
#endif
    let faces = try input.asset.faces.compactMap({ (face) -> Face? in
      guard let cgImage = face.faceCroppedImage.cgImage else {
        return nil
      }
      let MLRequestHandler = VNImageRequestHandler(cgImage: cgImage,
                                                   options: [:])
      try MLRequestHandler.perform([request])
      return embeddingsHandler(face: face,
                               request: request,
                               configuration: input.configuration)
    })
    let asset = ProcessAsset(identifier: input.asset.identifier,
                             image: input.asset.image,
                             tags: input.asset.tags,
                             boundingBoxes: input.asset.normalizedBoundingBoxes,
                             faces: faces,
                             text: input.asset.text)
    
    return ProcessInput(asset: asset, configuration: input.configuration)
  }
  
  private func imageQuality(input: ProcessInput) throws -> ProcessInput {
    guard input.configuration.minimumQualityFilter != .none else {
      return input
    }
    precondition(input.asset.image.cgImage != nil, "must provide cgImage \(input.asset.identifier)")
    
    let requestHandler = VNImageRequestHandler(cgImage: input.asset.image.cgImage!, options: [:])
    let request = VNDetectFaceCaptureQualityRequest()
#if targetEnvironment(simulator)
    request.usesCPUOnly = true
#endif
    if !input.asset.faces.isEmpty {
      request.inputFaceObservations = input.asset.faces.map({ $0.faceObservation })
    }
    try requestHandler.perform([request])
    guard let observations = request.results else {
      throw VisionProcessError.facesDetecting
    }
    guard observations.count == input.asset.faces.count else {
      
      let faces = observations.compactMap { (observation) -> Face? in
        if observation.faceCaptureQuality ?? 0 < input.configuration.minimumQualityFilter.value {
          return nil
        }
        return Face(localIdentifier: input.asset.identifier,
                    faceCroppedImage: UIImage(),
                    faceObservation: observation,
                    quality: observation.faceCaptureQuality ?? 0,
                    roll: 0,
                    faceEncoding: [],
                    faceEmotion: .none)
      }
      
      let asset = ProcessAsset(identifier: input.asset.identifier,
                               image: input.asset.image,
                               tags: input.asset.tags,
                               boundingBoxes: boundingBoxToRects(observation: observations),
                               faces: faces,
                               text: input.asset.text)
      return ProcessInput(asset: asset, configuration: input.configuration)
    }
    let faces = zip(input.asset.faces, observations).compactMap { (face, observation) -> Face? in
      if observation.faceCaptureQuality ?? 0 < input.configuration.minimumQualityFilter.value {
        return nil
      }
      return Face(localIdentifier: face.localIdentifier,
                  faceCroppedImage: face.faceCroppedImage,
                  faceObservation: face.faceObservation,
                  quality: observation.faceCaptureQuality ?? 0,
                  roll: face.roll,
                  faceEncoding: face.faceEncoding,
                  faceEmotion: face.faceEmotion)
    }
    let asset = ProcessAsset(identifier: input.asset.identifier,
                             image: input.asset.image,
                             tags: input.asset.tags,
                             boundingBoxes: input.asset.normalizedBoundingBoxes,
                             faces: faces,
                             text: input.asset.text)
    return ProcessInput(asset: asset, configuration: input.configuration)
  }
  
  private func tagPhoto(input: ProcessInput) throws -> ProcessInput {
    let requestHandler = VNImageRequestHandler(cgImage: (input.asset.image.cgImage!), options: [:])
    let request = VNClassifyImageRequest()
#if targetEnvironment(simulator)
    request.usesCPUOnly = true
#endif
    try requestHandler.perform([request])
    var categories: [DetectedObject] = []
    
    if let observations = request.results {
      categories = observations
        .filter { $0.hasMinimumRecall(0.01, forPrecision: 0.9) }
        .reduce(into: [DetectedObject]()) { arr, observation in arr.append(DetectedObject(identifier: observation.identifier , confidence: observation.confidence, normalizedLocation: .zero))}
    }
    let asset = ProcessAsset(identifier: input.asset.identifier,
                             image: input.asset.image,
                             tags: categories,
                             boundingBoxes: input.asset.normalizedBoundingBoxes,
                             faces: input.asset.faces,
                             text: input.asset.text)
    return ProcessInput(asset: asset, configuration: input.configuration)
  }
  
  private func objectLocationDetection(input: ProcessInput) throws -> ProcessInput {
    return try autoreleasepool { () -> ProcessInput in
      precondition(input.asset.image.cgImage != nil, "must provide cgImage \(input.asset.identifier)")
      
      let model = try Models.getModel(by: .mobileNet_SSD)
      let request = VNCoreMLRequest(model: model)
      request.imageCropAndScaleOption = .scaleFill
#if targetEnvironment(simulator)
      request.usesCPUOnly = true
#endif
      let requestHandler = VNImageRequestHandler(cgImage: (input.asset.image.cgImage!), options: [:])
      try requestHandler.perform([request])
      
      
      guard let observations = request.results as? [VNRecognizedObjectObservation] else {
        return input
      }
      
      let objects = observations.map { (object) -> DetectedObject in
        DetectedObject(identifier: object.labels.first?.identifier ?? "",
                       confidence: object.confidence,
                       normalizedLocation: object.boundingBox)
      }
      
      let asset = ProcessAsset(identifier: input.asset.identifier,
                               image: input.asset.image,
                               tags: objects,
                               boundingBoxes: input.asset.normalizedBoundingBoxes,
                               faces: input.asset.faces,
                               text: input.asset.text)
      
      return ProcessInput(asset: asset, configuration: input.configuration)
      
    }
  }
  
  private func faceEmotionProcess(input: ProcessInput) throws -> ProcessInput {
    precondition(input.asset.image.cgImage != nil, "must provide cgImage \(input.asset.identifier)")
    
    let model = try Models.getModel(by: .faceExpression)
    let request = VNCoreMLRequest(model: model)
    request.imageCropAndScaleOption = .scaleFill
#if targetEnvironment(simulator)
    request.usesCPUOnly = true
#endif
    let requestHandler = VNImageRequestHandler(cgImage: (input.asset.image.cgImage!), options: [:])
    try requestHandler.perform([request])
    
    
    let faces = try input.asset.faces.compactMap({ (face) -> Face? in
      guard let cgImage = face.faceCroppedImage.cgImage else {
        return nil
      }
      let MLRequestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
      try MLRequestHandler.perform([request])
      return emotionHandler(face: face, request: request, configuration: input.configuration)
    })
    
    let asset = ProcessAsset(identifier: input.asset.identifier,
                             image: input.asset.image,
                             tags: input.asset.tags,
                             boundingBoxes: input.asset.normalizedBoundingBoxes,
                             faces: faces,
                             text: input.asset.text)
    
    return ProcessInput(asset: asset, configuration: input.configuration)
  }
  
  func custom<T>(model: MLModel) -> CustomFilter<T> {
    return { input in
      return try autoreleasepool { () -> T in
        guard let model = try? VNCoreMLModel(for: model) else {
          throw VisionProcessError.unknown
        }
        let request =  VNCoreMLRequest(model:model)
#if targetEnvironment(simulator)
        request.usesCPUOnly = true
#endif
        request.imageCropAndScaleOption = .centerCrop
        let requestHandler = VNImageRequestHandler(cgImage: (input.asset.image.cgImage!), options: [:])
        try requestHandler.perform([request])
        guard let results = request.results as? T else {
          throw VisionProcessError.unknown
        }
        return results
      }
    }
  }
  
  // Fetch image from PHAsset
  private func fetchAsset(input: ProcessInput) throws -> ProcessInput {
    return autoreleasepool { () -> ProcessInput in
      let fetchingOptions = ImageFetcherOptions(downsampleImageSize: input.configuration.fetchImageSize)
      let imageFetcher = ImageFetcherService(options: fetchingOptions)
      if input.asset.image.size.area > 0 {
        return input
      }
      if let image = imageFetcher.image(from: input.asset.identifier) {
        let asset = ProcessAsset(identifier: input.asset.identifier,
                                 image: image)
        return ProcessInput(asset: asset, configuration: input.configuration)
      }
      let asset = ProcessAsset(identifier: input.asset.identifier,
                               image: UIImage())
      return ProcessInput(asset: asset, configuration: input.configuration)
    }
  }
  
  private func cropChipFaces(input: ProcessInput) throws -> ProcessInput {
    return autoreleasepool { () -> ProcessInput in
      let faces = input.asset.faces.map({ extractChip(face: $0,
                                                      image: input.asset.image,
                                                      processConfiguration: input.configuration
      )})
      
      let asset = ProcessAsset(identifier: input.asset.identifier,
                               image: input.asset.image,
                               tags: input.asset.tags,
                               boundingBoxes: input.asset.normalizedBoundingBoxes,
                               faces: faces,
                               text: input.asset.text)
      return ProcessInput(asset: asset, configuration: input.configuration)
    }
  }
  
  // Convert ProcessAsset To ProcessedAsset
  // Remove main image to reduce ram foot print
  func clean(input: ProcessInput) throws -> ProcessOutput {
    ProcessOutput(asset: input.asset)
  }
}

private extension LKActions {

  func boundingBoxToRects(observation: [VNFaceObservation]) -> [CGRect] {
    observation.map(convertRect)
  }

  func convertRect(face: VNFaceObservation) -> CGRect {
    return face.boundingBox
  }

  func hasMinimumLandmarkRequirement(observation: VNFaceObservation,
                                     input: ProcessInput) -> Bool {
    let area = observation.boundingBox.size.scale(imageSize: input.asset.image.size).area
    if observation.yaw?.doubleValue ?? 0 < -1.5 || observation.yaw?.doubleValue ?? 0 > 1.5 {
      return false
    }
    // remove low res face chip
    if area < input.configuration.minimumFaceArea {
      return false
    }
    return true
  }

  func embeddingsHandler(
    face: Face,
    request: VNRequest,
    configuration: ProcessConfiguration
  ) -> Face {
    guard let observations = request.results as? [VNCoreMLFeatureValueObservation] ,
          let firstObserve = observations.first,
          let emb = firstObserve.featureValue.multiArrayValue else {
      return face
    }
    switch configuration.faceEncoderModel {

    case .facenet:
      let embedded = buffer2Array(length: emb.count, data: emb.dataPointer, Double.self)
      |> norm_l2
      return Face(localIdentifier: face.localIdentifier,
                  faceCroppedImage: face.faceCroppedImage,
                  faceObservation: face.faceObservation,
                  quality: face.quality,
                  roll: face.roll,
                  faceEncoding: embedded,
                  faceEmotion: face.faceEmotion)
    case .VGGFace2_senet_Lite, .VGGFace2_resnet_Lite:
      let embedded = buffer2Array(length: emb.count, data: emb.dataPointer, Float.self).map({ Double($0) })
      |> norm_l2
      return Face(localIdentifier: face.localIdentifier,
                  faceCroppedImage: face.faceCroppedImage,
                  faceObservation: face.faceObservation,
                  quality: face.quality,
                  roll: face.roll,
                  faceEncoding: embedded,
                  faceEmotion: face.faceEmotion)
    }

  }

  func emotionHandler(face: Face,
                      request: VNRequest,
                      configuration: ProcessConfiguration) -> Face {
    guard let observations = request.results as? [VNCoreMLFeatureValueObservation] ,
          let firstObserve = observations.first,
          let emb = firstObserve.featureValue.multiArrayValue else {
      return face
    }
    let buff = buffer2Array(length: emb.count, data: emb.dataPointer, Float.self)
    let maxIndex = zip(buff.indices, buff).max(by: { $0.1 < $1.1 })?.0 ?? 7
    let emotion = Face.FaceEmotion.allCases[maxIndex]
    
    return Face(localIdentifier: face.localIdentifier,
                faceCroppedImage: face.faceCroppedImage,
                faceObservation: face.faceObservation,
                quality: face.quality,
                roll: face.roll,
                faceEncoding: face.faceEncoding,
                faceEmotion: emotion)
    
  }

  func buffer2Array<T>(length: Int, data: UnsafeMutableRawPointer, _: T.Type) -> [T] {
    let ptr = data.bindMemory(to: T.self, capacity: length)
    let buffer = UnsafeBufferPointer(start: ptr, count: length)
    return Array(buffer)
  }

  func norm_l2(emb: [Double]) -> [Double] {
    let sum: Double = emb.reduce(0) { (result, next) in
      return result + next * next
    }
    let emb: [Double] = emb.compactMap({ return $0/sqrt(sum) })
    return emb
  }

  func norm_l1(emb: [Double]) -> [Double] {
    let sum: Double = emb.reduce(0) { (result, next) in
      return result + next * next
    }
    let emb: [Double] = emb.compactMap({ return $0/(sum) })
    return emb
  }

  func average(arrays: [[Double]] ) -> [Double] {
    var average:[Double] = []
    if !(arrays.count > 0) {
      return arrays.first!
    }
    for i in 0...arrays.first!.count - 1 {
      var columnSum: Double = 0.0
      for j in 0...arrays.count - 1 {
        columnSum += arrays[j][i]
      }
      average.append(columnSum/Double(arrays.count))
    }
    return average
  }
  
  func extractChip(face: Face,
                   image: UIImage,
                   processConfiguration: ProcessConfiguration) -> Face {
    let chipImage = Interpolation.extractImageChip(image,
                                                   chipDetail: Interpolation
      .getFaceChipDetails(det: face.faceObservation,
                          imageSize: image.size,
                          size: processConfiguration.faceChipSize,
                          padding: processConfiguration.faceChipPadding,
                          processConfiguration: processConfiguration),
                                                   observation: face.faceObservation, processConfiguration: processConfiguration)
    return Face(localIdentifier: face.localIdentifier,
                faceCroppedImage: chipImage.image ?? UIImage(),
                faceObservation: face.faceObservation,
                quality: face.quality,
                roll: chipImage.roll,
                faceEncoding: face.faceEncoding,
                faceEmotion: face.faceEmotion)
  }
}
