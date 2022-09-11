//  Created by Amir Lahav on 30/07/2022.
//  Copyright © 2019 la-labs. All rights reserved.

public enum TaskResult<Success: Sendable>: Sendable {
  case success(Success)
  case failure(Error)

  public init(_ body: @Sendable () async throws -> Success) async {
    do {
      let result = try await body()
      self = .success(result)
    } catch {
      self = .failure(error)
    }
  }
}
