//  Copyright © 2019 la-labs. All rights reserved.

import Foundation
import Photos

public class ImageFetcherOptions {
    
    let downsampleImageSize: CGFloat
    let requestOptions: PHImageRequestOptions
    
    public init(
        downsampleImageSize: CGFloat = 400,
        requestOptions: PHImageRequestOptions = PHImageRequestOptions.defaultOptions) {
        self.downsampleImageSize = downsampleImageSize
        self.requestOptions = requestOptions
        self.requestOptions.isSynchronous = true
    }
    
}
