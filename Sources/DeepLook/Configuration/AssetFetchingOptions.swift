//
//  AssetFetchingOptions.swift
//  
//
//  Created by Amir Lahav on 23/09/2020.
//  Copyright © 2019 la-labs. All rights reserved.

import Foundation
import Photos

public class AssetFetchingOptions {
    
    public init(sortDescriptors: [NSSortDescriptor]? = nil,
         assetCollection: AssetCollection = .allPhotos,
         fetchLimit: Int = Int.max) {
        self.sortDescriptors = sortDescriptors
        self.assetCollection = assetCollection
        self.fetchLimit = fetchLimit
    }
    let sortDescriptors: [NSSortDescriptor]?
    let assetCollection: AssetCollection
    let fetchLimit: Int
}

