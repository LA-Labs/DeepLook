//
//  ActionType.swift
//  
//
//  Created by Amir Lahav on 30/06/2022.
//

import Foundation

public struct ActionType {
  public var process: (ProcessInput) async throws -> ProcessInput
}

public extension ActionType {
  static func +(lhs: ActionType, rhs: ActionType) -> ActionType {
    ActionType(process: lhs.process >>> rhs.process)
  }
}

public extension ActionType {
  static var faceLocation: ActionType {
    .init(process: Actions.faceLocation)
  }

  static var objectDetecting: ActionType {
    .init(process: Actions.objectDetecting)
  }

  static var objectLocation: ActionType {
    .init(process: Actions.objectLocation)
  }

  static var faceEncoding: ActionType {
    .init(process: Actions.faceEncoding)
  }

  static var faceEmotion: ActionType {
    .init(process: Actions.faceEmotion)
  }

  static var faceQuality: ActionType {
    .init(process: Actions.faceQuality)
  }
}
