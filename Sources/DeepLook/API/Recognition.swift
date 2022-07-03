//
//  Recognition.swift
//  DeepLook
//
//  Created by Amir Lahav on 27/02/2021.
//  Copyright © 2019 la-labs. All rights reserved.

import Foundation
import UIKit

/// Reference to `LKRecognition.default` for quick bootstrapping and examples.
public let Recognition = LKRecognition.default

public class LKRecognition {
    
    // shared instance
    public static let `default` = LKRecognition()
    
    // initiate only once.
    private init() { }
    
    /// Group faces by similarity.
    ///
    /// This function fetch asset from the user gallery and cluster all recognize faces in groups.
    /// You can control the group clustering by changing the distance threshold in the clusterOptions.
    /// - Parameters:
    ///   - fetchOptions: Describe fetching options like fetch limit, sort descriptor and more.
    ///   - clusterOptions: Describe clustering options like cluster size, threshold and more.
    ///   - processConfiguration: Describe process options like feature detection algorithm, minimum face size etc.
    ///   - completion: Return 2d array of faces. Each array describes a face group.
    public func cluster(fetchOptions: AssetFetchingOptions,
                        clusterOptions: ClusterOptions,
                        processConfiguration: ProcessConfiguration = ProcessConfiguration()
    ) async throws -> [[Face]] {
      let assets = Vision.assetService.stackInputs(with: fetchOptions,
                                                   processConfiguration: processConfiguration)

      precondition(!assets.isEmpty(), "Asset fetched must not be empty")
      let embedding = .faceQuality + .faceEncoding
      let startDate = Date()

      let photos = try await Vision.detect(
        objects: assets, process: embedding.process
      )

      let faces = photos.flatMap { (asset) -> [Face] in
        asset.faces
      }

      let groupedFaces = self.groupFaces(faces: faces,
                                         clusterOptions: clusterOptions)

      if Defaults.shared.print {
        defer {
          print("\n============************===============")
          print("Finish clustering in: \(startDate.timeIntervalSinceNow * -1) second\nTotal number of faces: \(faces.count)\nTotal number of clusters: \(groupedFaces.count)")
          print("============************===============")
        }
      }
      return groupedFaces
    }
    
    
    /// This function verifies an image pair is the same person or different persons.
    /// Every face founded from the source image will be compared against the target images.
    /// If you are going to call `verify` function for a list of image pairs, then you should pass an array instead of calling the function in for loops.
    /// - Parameters:
    ///   - sourceImage: Image input
    ///   - targetImages: Target images to verify faces. Can be a list of images
    ///   - similarityThreshold: Maximum distance threshold between faces
    ///   - processConfiguration: Describe process options like feature detection algorithm, minimum face size etc.
    ///
    ///         let face1 = UIImage(named: "face1")!
    ///         let face2 = UIImage(named: "face2")!
    ///         let face3 = UIImage(named: "face3")!
    ///
    ///         // ProcessConfiguration
    ///         let cofig = ProcessConfiguration()
    ///         cofig.faceEncoderModel = .facenet
    ///         cofig.landmarksAlignmentAlgorithm = .pointsSphereFace5
    ///         cofig.faceChipPadding = 0.0
    ///
    ///         // Start verify
    ///         Recognition.verify(sourceImage: face1,
    ///                            targetImages: face2, face3,
    ///                            similarityThreshold: 0.7,
    ///                            processConfiguration: cofig) { (result) in
    ///                            switch result {
    ///                                 case .success(let compression):
    ///                                     print(compression.count)
    ///                                 case .failure(let error):
    ///                                     print(error)
    ///                            }
    ///         }
    ///   - completion: Verify function returns an array of match faces.
    public func verify(sourceImage: UIImage,
                       targetImages: UIImage...,
                       similarityThreshold: Double,
                       processConfiguration: ProcessConfiguration = ProcessConfiguration()
    ) async throws -> [Match] {
        let faceEncoding =  .faceQuality + .faceEncoding
        let sourceImageAsset = ProcessAsset(identifier: "lhs",
                                            image: sourceImage)
        let sourceInput = ProcessInput(asset: sourceImageAsset,
                                       configuration: processConfiguration)
        let targetsInput = targetImages
            .map { (sourceImage) in
                ProcessAsset(identifier: "rhs", image: sourceImage)
            }.map { (processAsset) -> ProcessInput in
                ProcessInput(asset: processAsset, configuration: processConfiguration)
            }.chunked(into: 10)
        var objects = Stack<[ProcessInput]>()
        objects.push([sourceInput])
        targetsInput.forEach { (inputs) in
            objects.push(inputs)
        }
      return try await verify(stack: objects, process: faceEncoding.process,
                              similarityThreshold: similarityThreshold)
    }
    
    
    /// This function find an image pair is same person or different persons in a batch of photos.
    /// Every face founded from the source image will be compared against the fetch images from the user gallery.
    
    /// - Parameters:
    ///   - sourceImage: Image input
    ///   - galleyFetchOptions: Describe fetching options like fetch limit, sort descriptor and more.
    ///   - similarityThreshold: Maximum distance threshold between faces
    ///   - processConfiguration: Describe process options like feature detection algorithm, minimum face size and more.
    ///
    ///         let face1 = UIImage(named: "face1")!
    ///
    ///         // fetch the last 100 photos from the user gallery.
    ///         let fetchAssetOptions = AssetFetchingOptions(sortDescriptors: nil,
    ///                                                      assetCollection: .allAssets,
    ///                                                      fetchLimit: 100)
    ///         // ProcessConfiguration
    ///         let config = ProcessConfiguration()
    ///         config.faceEncoderModel = .facenet
    ///         config.landmarksAlignmentAlgorithm = .pointsSphereFace5
    ///         config.faceChipPadding = 0.0
    ///
    ///         // Start verify
    ///         Recognition.verify(sourceImage: face1,
    ///                            galleyFetchOptions: fetchAssetOptions,
    ///                            similarityThreshold: 0.7,
    ///                            processConfiguration: config) { (result) in
    ///                            switch result {
    ///                                 case .success(let compression):
    ///                                     print(compression.count)
    ///                                 case .failure(let error):
    ///                                     print(error)
    ///                            }
    ///         }
    ///   - completion: Find function returns an array of match faces.
    public func find(sourceImage: UIImage,
                     galleyFetchOptions: AssetFetchingOptions,
                     similarityThreshold: Double,
                     processConfiguration: ProcessConfiguration = ProcessConfiguration()
    ) async throws -> [Match] {
      let faceEncoding =  .faceQuality + .faceEncoding
      let sourceImageAsset = ProcessAsset(identifier: "lhs",
                                          image: sourceImage)
      let sourceInput = ProcessInput(asset: sourceImageAsset,
                                     configuration: processConfiguration)
      var objects = Vision.assetService.stackInputs(with: galleyFetchOptions,
                                                    processConfiguration: processConfiguration)
      objects.push([sourceInput])
      return try await verify(stack: objects,
                              process: faceEncoding.process,
                              similarityThreshold: similarityThreshold)
    }
    
    
    /// This function find an image pair is same person or different persons in a batch of photos.
    /// Every face founded from the source image will be compared against the fetch images from the user gallery.
    
    /// - Parameters:
    ///   - phAssetLocalIdentifier: Local identifier of the desire image from the user gallery.
    ///   - galleyFetchOptions: Describe fetching options like fetch limit, sort descriptor and more.
    ///   - similarityThreshold: Maximum distance threshold between faces
    ///   - processConfiguration: Describe process options like feature detection algorithm, minimum face size and more.
    ///
    ///         // fetch the last 100 photos from the user gallery.
    ///         let fetchAssetOptions = AssetFetchingOptions(sortDescriptors: nil,
    ///                                                      assetCollection: .allAssets,
    ///                                                      fetchLimit: 100)
    ///         // ProcessConfiguration
    ///         let config = ProcessConfiguration()
    ///         config.faceEncoderModel = .facenet
    ///         config.landmarksAlignmentAlgorithm = .pointsSphereFace5
    ///         config.faceChipPadding = 0.0
    ///
    ///         // Start verify
    ///         Recognition.verify(sourceImage: "local identifier",
    ///                            galleyFetchOptions: fetchAssetOptions,
    ///                            similarityThreshold: 0.7,
    ///                            processConfiguration: config) { (result) in
    ///                            switch result {
    ///                                 case .success(let compression):
    ///                                     print(compression.count)
    ///                                 case .failure(let error):
    ///                                     print(error)
    ///                            }
    ///         }
    ///   - completion: Verify function returns an array of match faces.
    public func find(phAssetLocalIdentifier: String,
                     galleyFetchOptions: AssetFetchingOptions,
                     similarityThreshold: Double,
                     processConfiguration: ProcessConfiguration = ProcessConfiguration()
    ) async throws -> [Match] {
      let faceEncoding =  Actions.faceQuality >>> Actions.faceEncoding
      let sourceImageAsset = ProcessAsset(identifier: phAssetLocalIdentifier,
                                          image: UIImage())
      let sourceInput = ProcessInput(asset: sourceImageAsset,
                                     configuration: processConfiguration)
      var objects = Vision.assetService.stackInputs(with: galleyFetchOptions,
                                                    processConfiguration: processConfiguration)
      objects.push([sourceInput])
      let assets = try await Vision.detect(objects: objects, process: faceEncoding)
      let (sourceFace, targetFace) = assets.flatMap { (asset) -> [Face] in
        asset.faces
      }.stablePartition(by: { $0.localIdentifier == "lhs" })
      return self.findMatches(sourceFaces: sourceFace,
                              targetFaces: targetFace,
                              similarityDistance: similarityThreshold)
    }
    
    
    
    public func facesEncoding(_ sourceImages: UIImage...,
                              processConfiguration: ProcessConfiguration = ProcessConfiguration()
    ) async throws -> [Face] {
        let faceEncoding = Actions.faceQuality >>> Actions.faceEncoding
        let input = sourceImages.map { (sourceImage) in
            ProcessAsset(identifier: "sourceImage", image: sourceImage)
        }.map { (processAsset) -> ProcessInput in
            ProcessInput(asset: processAsset,
                         configuration: processConfiguration)
        }.chunked(into: 10)
        var objects = Stack<[ProcessInput]>()
        input.forEach { (inputs) in
            objects.push(inputs)
        }
      return try await Vision.detect(objects: objects, process: faceEncoding)
        .flatMap({ $0.faces })
    }
    
    
    
    public func facesEncoding(fetchOptions: AssetFetchingOptions,
                              processConfiguration: ProcessConfiguration = ProcessConfiguration()
     ) async throws -> [Face] {
        let faceEncoding = Actions.faceQuality >>> Actions.faceEncoding
        let assets = Vision.assetService.stackInputs(with: fetchOptions,
                                                     processConfiguration: processConfiguration)
      return try await Vision.detect(objects: assets, process: faceEncoding)
        .flatMap({ $0.faces })
    }
}

private extension LKRecognition {
  func groupFaces(faces: [Face], clusterOptions: ClusterOptions) -> [[Face]] {
    switch clusterOptions.clusterType {
    case .DBSCAN:
      return Cluster._DBSCAN.cluster(values: faces,
                                     epsilon: clusterOptions.threshold,
                                     minimumNumberOfPoints: 1,
                                     distanceFunction: { (a, b) -> Double in
        if a.localIdentifier != b.localIdentifier {
          return a.distance(to: b)
        }else {
          return Double.greatestFiniteMagnitude
        }
      })
    case .ChineseWhispers:
      let labels = Cluster
        .ChineseWhispers
        .cluster(objects: faces,
                 distanceFunction: { (a, b) -> Double in
          a.distance(to: b)
        },
                 eps: clusterOptions.threshold,
                 numIterations: clusterOptions.numberIterations)
      return Cluster.ChineseWhispers.group(objects: faces,
                                           labels: labels).filter { (faces) -> Bool in
        faces.count > clusterOptions.minimumClusterSize
      }
    }
  }

  func findMatches(sourceFaces: [Face],
                   targetFaces: [Face],
                   similarityDistance: Double) -> [Match] {
    filterZipVerifiedFaces(sourceFaces: sourceFaces,
                           targetFaces: targetFaces,
                           similarityDistance: similarityDistance)
    .map { (faces) -> Match in
      Match(sourceFace: faces.0,
            targetFace: faces.1,
            distance: faces.0.distance(to: faces.1),
            threshold: similarityDistance)
    }
  }

  func filterVerifiedFaces(sourceFaces: [Face],
                           targetFaces: [Face],
                           similarityDistance: Double) -> [Face] {
    sourceFaces.commonElements(targetFaces) { (a, b) -> Bool in
      a.distance(to: b) <= similarityDistance
    }
  }

  func filterZipVerifiedFaces(sourceFaces: [Face], targetFaces: [Face], similarityDistance: Double) -> [(Face, Face)] {
    sourceFaces.commonZipElements(targetFaces) { (a, b) -> Bool in
      a.distance(to: b) <= similarityDistance
    }
  }

  func verify(stack: Stack<[ProcessInput]>,
              process: @escaping Action,
              similarityThreshold: Double) async throws -> [Match] {
    let assets = try await Vision.detect(objects: stack, process: process)
    let (sourceFace, targetFace) = assets.flatMap { (asset) -> [Face] in
      asset.faces
    }.stablePartition(by: { $0.localIdentifier == "lhs" })
    return self.findMatches(sourceFaces: sourceFace,
                            targetFaces: targetFace,
                            similarityDistance: similarityThreshold)
  }
}
