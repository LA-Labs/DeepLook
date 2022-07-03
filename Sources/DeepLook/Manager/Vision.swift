//
//  ALVisionManager.swift
//  ALFacerKit
//
//  Created by amir.lahav on 16/11/2019.
//  Copyright © 2019 la-labs. All rights reserved.
//

import Foundation
import CoreML
#if os(OSX)
import AppKit
#elseif os(iOS)
import UIKit
#endif

class Vision {
    static let assetService = AssetService()
}

extension Vision {

  static func detect(objects stack: Stack<[ProcessInput]>,
                     process: @escaping Action) async throws -> [ProcessOutput] {
    let pipe = Actions.fetchAsset() >>> process >>> Actions.clean
    return try await perform(on: stack, process: pipe)
  }

  static func detect<T>(in assets: UIImage,
                        model: MLModel, returnType: T.Type,
                        completion: @escaping (Result<T, VisionProcessError>)-> Void) {
    perform(image: assets, model: model, completion: completion)
  }

  static func perform(on stack: Stack<[ProcessInput]>,
                      process: @escaping JobPipeline) async throws -> [ProcessOutput] {
    try await stack |> doProcess(process)
  }


  static func perform<T>(image: UIImage, model: MLModel, completion: @escaping (Result<T, VisionProcessError>)-> Void) {
    let asset = ProcessAsset(identifier: "localIdentifier", image: image)
    let input = ProcessInput(asset: asset)
    let process: (ProcessInput) throws -> T = Actions.custom(model: model)
    do {
      let processed = try input |> process
      completion(.success(processed))
    } catch {
      completion(.failure(.error(error)))
    }
  }

  static func doProcess(
    _ process: @escaping JobPipeline
  ) throws -> GenericStackProcessor<ProcessInput,ProcessOutput>
  {
    let process = try Processor.makeSingleProcessProcessor(preformOn: process)
    return Processor.makeStackProcessor(processor: process)
  }
}
