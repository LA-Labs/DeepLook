//
//  Processor.swift
//
//  Created by amir.lahav on 16/11/2019.
//  Copyright © 2019 la-labs. All rights reserved.
//

import Foundation
import Photos

typealias SinglePipe<Input,Output> = (Input) throws -> Output
typealias MultiplePipe<Input,Output> = ([Input]) throws -> [Output]
typealias GenericStackProcessor<Input,Output> = (Stack<[Input]>) throws -> [Output]

typealias StackProcessor = (Stack<[ProcessAsset]>) throws -> [ProcessAsset]

class Processor {
    
    static var queue = DispatchQueue(label: "com.faceAi.la-labs")
    
    static func singleInputProcessor<Input, Output>(element: Input,
                                                    preformOn: @escaping SinglePipe<Input,Output>) -> Output {
        do {
            return try preformOn(element)
        }catch {
            fatalError()
            //TODO: handle error
        }
    }
    
    /// Create operation queue to process all assets.
    /// - Return analyzed objects
    /// - Parameter images: User Images
    static func singleProcessor<Input, Output>(element: [Input],
                                               preformOn: @escaping SinglePipe<Input,Output>) -> [Output] {
        let queue = OperationQueue()
        var objects: [Output] = []
        let blocks = element.map { (image) -> BlockOperation in
            return BlockOperation {
                do {
                    let object = try preformOn(image)
                    self.queue.sync {
                        objects.append(object)
                    }
                }catch {
                    //TODO: handle error
                }
            }
        }
        queue.addOperations(blocks, waitUntilFinished: true)
        return objects
    }
    
    /// Create operation queue to process all assets.
    /// - Return analyzed objects
    /// - Parameter images: User Images
    static func makeSingleProcessProcessor<Input, Output>(preformOn: @escaping SinglePipe<Input,Output>) -> MultiplePipe<Input, Output> {
        return { (element) in
            return singleProcessor(element: element, preformOn: preformOn)
        }
    }
    
    
    static func stackProcessor<Input, Output>(_ stack: Stack<[Input]>, processor: @escaping MultiplePipe<Input,Output>) -> [Output] {
        var stack = stack
        var objects: [Output] = []
        while !stack.isEmpty() {
            let startDate = Date()
            if let assets = stack.pop() {
                do {
                    let detectObjects = try processor(assets)
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
            return stackProcessor(stack, processor: processor)
        }
    }
}
