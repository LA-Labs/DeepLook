//  Created by amir lahav on 22/09/2020.
//  Copyright © 2019 la-labs. All rights reserved.

import Foundation
import Photos
import UIKit

class AssetService {
  
  init() { }
  
  func stackInputs(with options: AssetFetchingOptions? = nil,
                   processConfiguration: ProcessConfiguration,
                   chunkSize: Int = 10) -> Stack<[ProcessInput]> {
    let assets =  assetParser(assets: fetchAssets(with: options),
                              processConfiguration: processConfiguration)
    return chunk(assets: assets, chunkSize: chunkSize) |> stackAssets
  }
  
  /// Fetch assets from device gallery
  /// - Parameter options: Options for fetching assets like max number of photos, sorting options etc.
  /// - Returns: Collection of fetched PHAssets.
  func fetchAssets(with options: AssetFetchingOptions? = nil) -> PHFetchResult<PHAsset> {
    return fetchAssets(with: options ?? AssetFetchingOptions())
  }
}

private extension AssetService {

  private func stackAssets<T>(chunks: [[T]]) -> Stack<[T]> {
    var stack = Stack<[T]>()
    chunks.forEach({ stack.push($0) })
    return stack
  }

  private func chunk<T>(assets:[T], chunkSize:Int) -> [[T]] {
    assets.chunked(into: chunkSize)
  }

  func assetParser(assets: PHFetchResult<PHAsset>,
                   processConfiguration: ProcessConfiguration) -> [ProcessInput] {
    var assetsArray: [ProcessInput] = []
    assets.enumerateObjects { (asset, _, _) in
      if !(asset.mediaSubtypes == .photoScreenshot) {
        let asset = ProcessAsset(identifier: asset.localIdentifier,
                                 image: UIImage(),
                                 tags: [],
                                 boundingBoxes: [],
                                 faces: [],
                                 text: [])
        let input = ProcessInput(asset: asset,
                                 configuration: processConfiguration)
        assetsArray.append(input)
      }
    }
    return assetsArray
  }

  func fetchAssets(with options: AssetFetchingOptions) -> PHFetchResult<PHAsset> {
    precondition(PHPhotoLibrary.authorizationStatus() == .authorized, "You need to get Photos permissions first.")
    let fetchOption = PHFetchOptions()
    fetchOption.sortDescriptors = options.sortDescriptors
    fetchOption.fetchLimit = options.fetchLimit
    switch options.assetCollection {
    case .allPhotos:
      return PHAsset.fetchAssets(with: fetchOption)
    case .albumName(let albumName):
      let fetchOptions = PHFetchOptions()
      fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
      let collection: PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album,
                                                                              subtype: .any,
                                                                              options: fetchOptions)
      precondition(collection.firstObject != nil, "Album \(albumName) is empty")
      return PHAsset.fetchAssets(in: collection.firstObject!, options: fetchOption)
    case .assetCollection(let assetsCollection):
      return PHAsset.fetchAssets(in: assetsCollection, options: fetchOption)
    case .identifiers(let identifiers):
      return PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: fetchOption)
    }
  }
}
