//
//  AssetCollection.swift
//  
//
//  Created by Amir Lahav on 29/01/2021.
//  Copyright © 2019 la-labs. All rights reserved.

import Foundation
import Photos

public enum AssetCollection {
    case allPhotos
    case albumName(_ name: String)
    case assetCollection(_ collection: PHAssetCollection)
    case identifiers(_ ids: [String])
}
