//
//  Operator.swift
//  LookKit
//
//  Created by Amir Lahav on 29/01/2021.
//

import Foundation

precedencegroup ComparisonPrecedence {
    associativity: left
}

infix operator |> : ComparisonPrecedence
func |> <U, T> (x: U, f: (U) throws -> T) rethrows -> T {
    return try f(x)
}

// declare new operator
infix operator >> : ComparisonPrecedence
func >> <U, T, Z> (f: @escaping (U) ->T, g: @escaping (T)->Z) -> (U)->Z {
    return { g(f($0)) }
}

// declare new operator
infix operator --> : ComparisonPrecedence
public func --> <U, T, Z> (f: @escaping (U) throws ->T, g: @escaping (T) throws -> Z) -> (U) throws -> (Z) {
    return {try g(try f($0)) }
}

// declare new operator
infix operator >>> : ComparisonPrecedence
func >>> <U, N, T, Z> (f:@escaping (U,N) throws -> T, g: @escaping (T)->Z) -> (U,N) throws -> Z {
    return { g( try f($0, $1)) }
}
