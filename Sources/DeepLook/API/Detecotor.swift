//
//  Detector.swift
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

/// Reference to `LKDetector.default` for quick bootstrapping and examples.
public let Detector = LKDetector.default

public class LKDetector {
    
    // shared instance
    public static let `default` = LKDetector()
    
    // intimate only once.
    private init() { }
    
    //MARK: Public API
    /// Apply vision actions on user gallery photos.
    /// Action can be chained to preform multiple request
    /// Like Action.objectDetection --> Action.facelocation.
    /// - Parameters:
    ///   - actions: Action request like face location, object detection, face landmarks
    ///   - options: options for fetch asset from user galley.
    ///   Can be order and limited.
    ///   - processConfiguration: configuration for action process, like model, image size etc.
    ///   - completion: result contain list of ProcessOutput that contain all data requested.
    public func analyze(_ actions: @escaping Action,
                        with options: AssetFetchingOptions,
                        processConfiguration: ProcessConfiguration = ProcessConfiguration(),
                        completion: @escaping (Result<[ProcessOutput], VisionProcessError>) -> Void) {
        let assets = Vision.assetService.stackInputs(with: options,
                                                     processConfiguration: processConfiguration)
        Vision.detect(objects: assets, process: actions, completion: { result in
            switch result {
            case .success(let photos):
                completion(.success(photos))
                
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
    
    
    /// Apply vision actions on an image.
    /// Action can be chained to preform multiple request
    /// Like `Action.objectDetection` --> `Action.facelocation`.
    /// - Parameters:
    ///   - actions: Action request like face location, object detection, face landmarks
    ///   - sourceImage: Source image to perform on.
    ///   - processConfiguration: configuration for action process, like model, image size etc.
    ///   - completion: result contain list of ProcessOutput that contain all data requested.
    public func analyze(
        _ actions: @escaping Action,
        sourceImage: UIImage,
        processConfiguration: ProcessConfiguration = ProcessConfiguration(),
        completion: @escaping (Result<[ProcessOutput], VisionProcessError>) -> Void
    ) {
        analyze(actions,
                sourceImages: sourceImage,
                processConfiguration: processConfiguration,
                completion: completion)
    }
    
    
    /// Apply computer vision actions on multiple provided images.
    /// Action can be chained to preform multiple request
    /// Like `Action.objectDetection` --> `Action.facelocation`.
    /// - Parameters:
    ///   - actions: Action request like face location, object detection, face landmarks
    ///   - sourceImages: Source images to perform on.
    ///   - processConfiguration: configuration for action process, like model, image size etc.
    ///   - completion: result contain list of ProcessOutput that contain all data requested.
    public func analyze(
        _ actions: @escaping Action,
        sourceImages: UIImage...,
        processConfiguration: ProcessConfiguration = ProcessConfiguration(),
        completion: @escaping (Result<[ProcessOutput], VisionProcessError>) -> Void
    ) {
        analyze(actions,
                sourceImages: sourceImages,
                processConfiguration: processConfiguration,
                completion: completion)
    }
    
    public func faceLocations(
        in sourceImages: UIImage...,
        processConfiguration: ProcessConfiguration = ProcessConfiguration(),
        completion: @escaping (Result<[ProcessOutput], VisionProcessError>) -> Void
    ) {
        let faceLocation = Actions.faceLocation
        analyze(faceLocation,
                sourceImages: sourceImages,
                processConfiguration: processConfiguration,
                completion: completion)
    }
    
    public func objectLocations(
        in sourceImages: UIImage...,
        processConfiguration: ProcessConfiguration = ProcessConfiguration(),
        completion: @escaping (Result<[ProcessOutput], VisionProcessError>) -> Void
    ) {
        let objectLocation = Actions.objectLocation
        analyze(objectLocation,
                sourceImages: sourceImages,
                processConfiguration: processConfiguration,
                completion: completion)
    }
}


private extension LKDetector {
    func analyze(
        _ actions: @escaping Action,
        sourceImages: [UIImage],
        processConfiguration: ProcessConfiguration = ProcessConfiguration(),
        completion: @escaping (Result<[ProcessOutput], VisionProcessError>) -> Void
    ) {
        
        let inputAsset = sourceImages.map { (sourceImage) -> ProcessAsset in
            ProcessAsset(identifier: "sourceImage", image: sourceImage)
        }.map { (processAsset) -> ProcessInput in
            ProcessInput(asset: processAsset, configuration: processConfiguration)
        }.chunked(into: 10)
        var objects = Stack<[ProcessInput]>()
        inputAsset.forEach { (chunk) in
            objects.push(chunk)
        }
        Vision.detect(objects: objects, process: actions, completion: completion)
    }
}
