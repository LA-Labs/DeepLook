//  Copyright © 2019 la-labs. All rights reserved.

import Foundation

public struct ActionType<A> {
  public var process: (A) throws -> A
}

public extension ActionType {
  static func +(lhs: ActionType, rhs: ActionType) -> ActionType {
    ActionType(process: lhs.process >>> rhs.process)
  }
}

@available (iOS 13.0, *)
public extension ActionType {
  static var faceLocation: ActionType<ProcessInput> {
    .init(process: Actions.faceLocation)
  }

  static var objectDetecting: ActionType<ProcessInput> {
    .init(process: Actions.objectDetecting)
  }

  static var objectLocation: ActionType<ProcessInput> {
    .init(process: Actions.objectLocation)
  }

  static var faceEncoding: ActionType<ProcessInput> {
    .init(process: Actions.faceEncoding)
  }

  static var faceEmotion: ActionType<ProcessInput> {
    .init(process: Actions.faceEmotion)
  }

  static var faceQuality: ActionType<ProcessInput> {
    .init(process: Actions.faceQuality)
  }

  static var videoTextRecognition: ActionType<ProcessInput> {
    .init(process: Actions.videoTextRecognition)
  }
}
