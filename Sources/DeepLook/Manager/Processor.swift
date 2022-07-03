//
//  Processor.swift
//
//  Created by amir.lahav on 16/11/2019.
//  Copyright © 2019 la-labs. All rights reserved.
//

import Foundation
import Photos

typealias SinglePipe<Input,Output> = (Input) async throws -> Output
typealias MultiplePipe<Input,Output> = ([Input]) async throws -> [Output]
typealias GenericStackProcessor<Input,Output> = (Stack<[Input]>) async throws -> [Output]
typealias StackProcessor = (Stack<[ProcessAsset]>) throws -> [ProcessAsset]

class Processor {
    
    static var queue = DispatchQueue(label: "com.faceAi.la-labs")
    
    static func singleInputProcessor<Input, Output>(
      element: Input,
      preformOn: @escaping SinglePipe<Input,Output>
    ) async -> Output {
        do {
          return try await preformOn(element)
        }catch {
            fatalError()
            //TODO: handle error
        }
    }
    
    /// Create operation queue to process all assets.
    /// - Return analyzed objects
    /// - Parameter images: User Images
  static func singleProcessor<Input: Sendable, Output: Sendable>(
      elements: [Input],
      preformOn: @escaping SinglePipe<Input,Output>) async throws -> [Output] {
        do {
          let resultGroup = try await withThrowingTaskGroup(of: Output.self,
                                                            body: { taskGroup -> [Output] in
            for element in elements {
              taskGroup.addTask {
                return try await preformOn(element)
              }
            }
            var resultOutputs: [Output] = []
            for try await value in taskGroup {
              resultOutputs.append(value)
            }
            return resultOutputs
          }
          )
          return resultGroup
        }catch {
          throw error
        }
      }
    
    /// Create operation queue to process all assets.
    /// - Return analyzed objects
    /// - Parameter images: User Images
    static func makeSingleProcessProcessor<Input, Output>(preformOn: @escaping SinglePipe<Input,Output>) throws -> MultiplePipe<Input, Output> {
        return { (element) in
          return try await singleProcessor(elements: element, preformOn: preformOn)
        }
    }
    
    
  static func stackProcessor<Input, Output>(_ stack: Stack<[Input]>, processor: @escaping MultiplePipe<Input,Output>) async -> [Output] {
        var stack = stack
        var objects: [Output] = []
        while !stack.isEmpty() {
            let startDate = Date()
            if let assets = stack.pop() {
                do {
                  let detectObjects = try await processor(assets)
                    objects.append(contentsOf: detectObjects)
                    if Defaults.shared.print {
                        print("Finish \(assets.count) photos in: \(startDate.timeIntervalSinceNow * -1) second")
                    }
                } catch {   }
            }

        }
        return objects
    }
    
    static func makeStackProcessor<Input, Output>(processor: @escaping MultiplePipe<Input, Output>) -> GenericStackProcessor<Input, Output> {
        return { (stack) in
          return await stackProcessor(stack, processor: processor)
        }
    }
}
