//
//  Sequence + Extension.swift
//  LookKit
//
//  Created by Amir Lahav on 15/03/2021.
//  Copyright © 2019 la-labs. All rights reserved.

import Foundation

extension Sequence {
    func commonElements<U: Sequence>(_ rhs: U, compareFunction: (Self.Iterator.Element, U.Iterator.Element) -> Bool) -> [U.Iterator.Element]
    where Self.Iterator.Element: Equatable, Self.Iterator.Element == U.Iterator.Element {
        var common: [U.Iterator.Element] = []
        
        for lhsItem in self {
            for rhsItem in rhs {
                if compareFunction(lhsItem, rhsItem) {
                    common.append(rhsItem)
                }
            }
        }
        return common
    }
    
    func commonZipElements<U: Sequence>(_ rhs: U, compareFunction: (Self.Iterator.Element, U.Iterator.Element) -> Bool) -> [(lhs: Self.Iterator.Element, rhs: U.Iterator.Element)]
    where Self.Iterator.Element: Equatable, Self.Iterator.Element == U.Iterator.Element {
        var common: [(Self.Iterator.Element, U.Iterator.Element)] = []
        
        for lhsItem in self {
            for rhsItem in rhs {
                if compareFunction(lhsItem, rhsItem) {
                    common.append((lhsItem, rhsItem))
                }
            }
        }
        return common
    }
}
