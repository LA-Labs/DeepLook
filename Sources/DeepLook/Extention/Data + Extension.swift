//
//  Data + Extension.swift
//  LookKit
//
//  Created by amir.lahav on 21/09/2020.
//  Copyright © 2019 la-labs. All rights reserved.

import Foundation

#if os(OSX)
import AppKit
#elseif os(iOS)
import UIKit
#endif

extension Data {
    func downSample(to pointSize: CGSize,
                    scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(self as CFData, imageSourceOptions) else { return nil }
        
        let maxDimensionInPixels = Swift.max(pointSize.width ,pointSize.height ) * scale
        let downsampleOptions =
            [kCGImageSourceCreateThumbnailFromImageAlways: true,
             kCGImageSourceShouldCacheImmediately: true,
             kCGImageSourceCreateThumbnailWithTransform: true,
             kCGImageSourceThumbnailMaxPixelSize:maxDimensionInPixels] as CFDictionary
        guard let downsamoledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else { return nil }
        let image = UIImage(cgImage: downsamoledImage)
        return image
    }
    
    func downSample(to pointSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> CGImage? {
        
        let imageSourceOptions = [kCGImageSourceShouldCache:false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(self as CFData, imageSourceOptions) else { return nil }
        
        let maxDimensionInPixels = Swift.max(pointSize.width ,pointSize.height ) * scale
        let downsampleOptions =
            [kCGImageSourceCreateThumbnailFromImageAlways: true,
             kCGImageSourceShouldCacheImmediately: true,
             kCGImageSourceCreateThumbnailWithTransform: true,
             kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels] as CFDictionary
        return CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions)
    }
    
    static func downsample(imageAt imageURL: URL, to pointSize: CGSize) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        
        guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, imageSourceOptions) else { return nil }
        
        let maxDimensionInPixels = Swift.max(pointSize.width, pointSize.height) * UIScreen.main.scale
        let downsampleOptions =  [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                  kCGImageSourceShouldCacheImmediately: true,
                                  kCGImageSourceCreateThumbnailWithTransform: true,
                                  kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels] as CFDictionary
        let downsampledImage =   CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions)!
        let image = UIImage(cgImage: downsampledImage)
        return image
    }
}
