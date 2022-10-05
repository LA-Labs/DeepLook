//  Copyright © 2019 la-labs. All rights reserved.

import UIKit

/// Data model contain all observation from image analyze.
public struct ProcessOutput: Hashable {
    
    /// Original asset local identifier. on custom user image it might be "rhs"/"lhs".
    public let localIdentifier: String
    
    /// object founded in the image.
    public let tags: [DetectedObject]
    
    /// normalized bounding box for each face in the image.
    public let boundingBoxes: [CGRect]
    
    /// faces object contain data relevant for each face in the image.
    public let faces: [Face]
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(localIdentifier)
    }
    init(asset: ProcessAsset) {
        self.localIdentifier = asset.identifier
        self.tags = asset.tags
        self.boundingBoxes = asset.normalizedBoundingBoxes
        self.faces = asset.faces
    }
}
