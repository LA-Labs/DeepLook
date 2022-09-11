//  Created by amir.lahav on 16/11/2019.
//  Copyright © 2019 la-labs. All rights reserved.
//

import Foundation
import Photos

typealias SinglePipe<Input,Output> = (Input) throws -> Output
typealias AsyncSinglePipe<Input,Output> = (Input) async throws -> Output
typealias MultiplePipe<Input,Output> = ([Input]) throws -> [Output]
typealias AsyncMultiplePipe<Input,Output> = ([Input]) async throws -> [Output]
typealias GenericStackProcessor<Input,Output> = (Stack<[Input]>) async throws -> [Output]
typealias StackProcessor = (Stack<[ProcessAsset]>) throws -> [ProcessAsset]

class Processor {    
  static func singleInputProcessor<Input, Output>(
    element: Input,
    preformOn: @escaping AsyncSinglePipe<Input,Output>
  ) async -> Output {
    do {
      return try await preformOn(element)
    }catch {
      fatalError(error.localizedDescription)
    }
  }

  static func singleInputProcessor<Input, Output>(
    element: Input,
    preformOn: @escaping SinglePipe<Input,Output>
  ) -> Output {
    do {
      return try preformOn(element)
    }catch {
      fatalError(error.localizedDescription)
    }
  }

  /// Create operation queue to process all assets.
  /// - Return analyzed objects
  /// - Parameter images: User Images
  static func singleProcessor<Input: Sendable, Output: Sendable>(
    elements: [Input],
    preformOn: @escaping AsyncSinglePipe<Input,Output>) async throws -> [Output] {
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
  static func makeSingleProcessProcessor<Input, Output>(preformOn: @escaping AsyncSinglePipe<Input,Output>) throws -> AsyncMultiplePipe<Input, Output> {
    return { (element) in
      return try await singleProcessor(elements: element, preformOn: preformOn)
    }
  }


  static func stackProcessor<Input, Output>(
    _ stack: Stack<[Input]>,
    processor: @escaping MultiplePipe<Input,Output>
  ) throws -> [Output] {
    var stack = stack
    var objects: [Output] = []
    while !stack.isEmpty() {
      let startDate = Date()
      if let assets = stack.pop() {
        let detectObjects = try processor(assets)
        objects.append(contentsOf: detectObjects)
        if Defaults.shared.print {
          print("Finish \(assets.count) photos in: \(startDate.timeIntervalSinceNow * -1) second")
        }
      }
    }

    return objects
  }

  static func stackProcessor<Input, Output>(
    _ stack: Stack<[Input]>,
    processor: @escaping AsyncMultiplePipe<Input,Output>
  ) async throws -> [Output] {
    var stack = stack
    var objects: [Output] = []
    while !stack.isEmpty() {
      let startDate = Date()
      if let assets = stack.pop() {
        let processedObjects = try await processor(assets)
        objects.append(contentsOf: processedObjects)
        if Defaults.shared.print {
          print("Finish \(assets.count) photos in: \(startDate.timeIntervalSinceNow * -1) second")
        }
      }
    }

    return objects
  }

  static func makeStackProcessor<Input, Output>(processor: @escaping MultiplePipe<Input, Output>) throws -> GenericStackProcessor<Input, Output> {
    return { (stack) in
      try stackProcessor(stack, processor: processor)
    }
  }

  static func makeStackProcessor<Input, Output>(processor: @escaping AsyncMultiplePipe<Input, Output>) throws -> GenericStackProcessor<Input, Output> {
    return { (stack) in
      try await stackProcessor(stack, processor: processor)
    }
  }
}
