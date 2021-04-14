//
//  Scaling.swift
//  
//
//  Created by amir.lahav on 21/09/2019.
//  Copyright © 2019 la-labs. All rights reserved.
//

import Foundation
import CoreML
import Accelerate

@objc(scaling) class scaling: NSObject, MLCustomLayer {

    let scale: Float
    
    required init(parameters: [String : Any]) throws {
        
        if let scale = parameters["scale"] as? NSNumber {
            self.scale = scale.floatValue
        } else {
            self.scale = 1.0
        }

        super.init()
    }
    
    func setWeightData(_ weights: [Data]) throws {
        
        // This layer does not have any learned weights. However, in the conversion
        // script we added some (random) weights anyway, just to see how this works.
        // Here you would copy those weights into a buffer (such as MTLBuffer).
    }
    
    func outputShapes(forInputShapes inputShapes: [[NSNumber]]) throws -> [[NSNumber]] {
        
        // This layer does not modify the size of the data.
        return inputShapes
    }
    
    func evaluate(inputs: [MLMultiArray], outputs: [MLMultiArray]) throws {
        
        for i in 0..<inputs.count {
            let input = inputs[i]
            let output = outputs[i]
            
            let count = input.count
            let inputPointer = UnsafeMutablePointer<Float>(OpaquePointer(input.dataPointer))
            let outputPointer = UnsafeMutablePointer<Float>(OpaquePointer(output.dataPointer))
            var scale = self.scale
            vDSP_vsmul(inputPointer, 1, &scale, outputPointer, 1, vDSP_Length(count))
        }
    }
}
