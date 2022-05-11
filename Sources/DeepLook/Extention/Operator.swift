//
//  Operator.swift
//  LookKit
//
//  Created by Amir Lahav on 29/01/2021.
//

import Foundation

precedencegroup ApplyingPrecedence {
    associativity: left
}

infix operator |> : ApplyingPrecedence
func |> <U, T> (x: U, f: (U) throws -> T) rethrows -> T {
    return try f(x)
}

precedencegroup ComparisonPrecedence {
    associativity: left
    higherThan: ApplyingPrecedence
}

// declare new operator
infix operator >>> : ComparisonPrecedence

func >>> <U, T, Z> (f: @escaping (U) ->T, g: @escaping (T) -> Z) -> (U) -> Z {
    return { g(f($0)) }
}

public func >>> <U, T, Z> (f: @escaping (U) throws ->T, g: @escaping (T) throws -> Z) -> (U) throws -> (Z) {
    return { try g(try f($0)) }
}

func >>> <U, N, T, Z> (f: @escaping (U,N) throws -> T, g: @escaping (T) throws -> Z) rethrows -> (U,N) throws -> Z {
    return { try g(try f($0, $1)) }
}
