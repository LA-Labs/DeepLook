//  Created by Amir Lahav on 05/08/2022.
//  Copyright © 2019 la-labs. All rights reserved.

import Foundation

public extension Sequence {

  func map<Value>(_ keyPath: KeyPath<Element, Value>) -> [Value] {
    map { $0[keyPath: keyPath] }
  }

  func compactMap<Value>(_ keyPath: KeyPath<Element, Value>) -> [Value] {
    compactMap { $0[keyPath: keyPath] }
  }

  func flatMap<Value>(_ keyPath: KeyPath<Element, Value>) -> [Value] {
    compactMap { $0[keyPath: keyPath] }
  }

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
