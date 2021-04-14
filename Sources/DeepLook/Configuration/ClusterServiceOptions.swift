//
//  ClusterOptions.swift
//  
//
//  Created by amir.lahav on 21/09/2020.
//  Copyright © 2019 la-labs. All rights reserved.

import Foundation

/// Modify cluster options
public struct ClusterOptions {
    /// Minimum number of objects in cluster.
    /// Must be positive number larger than 0.
    let minimumClusterSize: Int
    
    /// Number of iteration uses by the cluster algorithm
    let numberIterations: Int
    
    /// Maximum distance between to objects
    let threshold: Double
    
    /// Which cluster algorithm to group objects
    let clusterType: ClusterType
    
    public init(minimumClusterSize: Int = 1,
                numberIterations: Int = 100,
                faceSimilarityThreshold: Double = 0.7,
                clusterType: ClusterType = .ChineseWhispers) {
        self.minimumClusterSize = minimumClusterSize
        self.numberIterations = numberIterations
        self.threshold = faceSimilarityThreshold
        self.clusterType = clusterType
    }
}
