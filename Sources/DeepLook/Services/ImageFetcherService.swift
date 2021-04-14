//
//  ImageFetcherService.swift
//  
//
//  Created by amir lahav on 21/09/2020.
//  Copyright © 2019 la-labs. All rights reserved.

import Foundation
import Photos
#if os(OSX)
import AppKit
#elseif os(iOS)
import UIKit
#endif


public class ImageFetcherService {
    
    private let imgManager = PHImageManager.default()
    private let options: ImageFetcherOptions
    
    /// This service help to fetch image from PHAssets
    /// - Parameter options: class options include image size etc.
    public init(options: ImageFetcherOptions) {
        self.options = options
    }
    
    func image(from phAsset: PHAsset) -> UIImage?  {

        return autoreleasepool { () -> UIImage? in
            var myImage:UIImage?
            imgManager.requestImageDataAndOrientation(for: phAsset, options: options.requestOptions) { [self] (data, str, ori, _) in
                    myImage = data?.downSample(to: CGSize(width: options.downsampleImageSize, height: options.downsampleImageSize), scale: UIScreen.main.scale)
                }
            return myImage
        }
    }
    
    public func image(from identifier: String) -> UIImage?  {

        return autoreleasepool { () -> UIImage? in
            var myImage: UIImage?
            guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject else {
                return nil
            }
            imgManager.requestImageDataAndOrientation(for: asset, options: options.requestOptions) { [self] (data, str, ori, _) in
                    myImage = data?.downSample(to: CGSize(width: options.downsampleImageSize, height: options.downsampleImageSize), scale: UIScreen.main.scale)
                }
            return myImage
        }
    }
    
    private func cgImage(from phAsset: PHAsset) -> CGImage? {

        return autoreleasepool { () -> CGImage? in
            var myImage: CGImage?
                
            imgManager.requestImageDataAndOrientation(for: phAsset, options: options.requestOptions) { [self] (data, str, ori, _) in
                myImage = data?.downSample(to: CGSize(width: options.downsampleImageSize, height: options.downsampleImageSize), scale: UIScreen.main.scale)
                }
            return myImage
        }
    }
}
