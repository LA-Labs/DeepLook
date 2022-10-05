//  Copyright © 2019 la-labs. All rights reserved.

import UIKit
import Vision

public class ProcessConfiguration {

  public init() {}


  /// Maximum dimension for fetching image from user gallery
  ///
  /// The default value is 500 points
  @NonNegative public var fetchImageSize: CGFloat = 500


  /// Use landmarks for similarity transformation
  public enum LandmarksAlignmentAlgorithm {

    /// 32 points from Dlib face alignment
    case pointsDlib32

    /// 5 points from Dlib face alignment
    case pointsDlib5

    /// 5 points from Sphere-face algorithm
    case pointsSphereFace5

  }

  /// Algorithm for face alignment
  public var landmarksAlignmentAlgorithm: LandmarksAlignmentAlgorithm = .pointsSphereFace5


  public enum FaceEncoderModel {

    /// Google facenet
    case facenet

    /// Quantize version of VGGFace2 based on Resent50
    case VGGFace2_resnet_Lite

    /// Quantize version of VGGFace2 based on Senet50
    case VGGFace2_senet_Lite

  }


  /// Model encoder for face image to vector representation.
  ///
  /// The default value is facenet
  public var faceEncoderModel: FaceEncoderModel = .facenet


  /// Minimum face square area to keep detecting object in pipe
  ///
  /// The default value is 2500 points (50x50) points
  @NonNegative public var minimumFaceArea: CGFloat = 2500



  /// Cropped chip to square size.
  ///
  /// for VGGFace2_resnet_Lite and VGGFace2_senet_Lite use 224
  /// facenet use 160
  ///
  /// The default value is 160
  @NonNegative public var faceChipSize: Double = 160


  /// Add padding to cropped chip.
  /// Values can be in range [-1,1].
  @Clamping(-1.0...1.0) public var faceChipPadding: Double = 0.0


  ///  A filter that specifies a quality bar for how much filtering is done to identify faces.
  ///  Filtered faces aren't compared. If you specify Low, Medium, or High, filtering removes all
  ///  faces that don’t meet the chosen quality bar. The quality bar is based on a variety of common
  ///  use cases. Low-quality detections can occur for a number of reasons. Some examples are an
  ///  object that's misidentified as a face, a face that's too blurry, or a face with a pose that's
  ///  too extreme to use. If you specify None, no filtering is performed.
  ///
  ///  The default value is low.
  public var minimumQualityFilter: QualityFilter = .low

  /// Region of interest in 1 unit.
  /// default value is the entire frame.
  public var roi: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)

  
  //MARK: Debug
  /// Draw landmark points on the processed image
  ///
  ///  The default value is false.
  public var drawFeaturePoints: Bool = false

  /// A value that determines whether the request prioritizes accuracy or speed in text
  /// recognition.
  /// Default level is fast.
  public var textRecognitionLevel: VNRequestTextRecognitionLevel = .fast

  /// A Boolean value that indicates whether the request applies language correction during the
  /// recognition process.
  /// Default value is false.
  public var usesLanguageCorrection: Bool = false
}
