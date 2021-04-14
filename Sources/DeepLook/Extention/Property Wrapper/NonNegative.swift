//
//  NonNegative.swift
//  LookKit
//
//  Created by Amir Lahav on 11/03/2021.
//  Copyright © 2019 la-labs. All rights reserved.

import Foundation

@propertyWrapper
public struct NonNegative<Value: Numeric & Comparable> {
    var value: Value
    
    public init(wrappedValue: Value) {
        self.value = wrappedValue < 0 ? 0 : wrappedValue
    }
    
    public var wrappedValue: Value {
        get { value }
        set { value = newValue < 0 ? 0 : newValue }
    }
}
