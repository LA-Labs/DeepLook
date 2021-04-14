//
//  PHImageRequestOptions + Extension.swift
//  LookKit
//
//  Created by amir.lahav on 21/09/2020.
//  Copyright © 2019 la-labs. All rights reserved.

import Foundation
import Photos

extension PHImageRequestOptions {
    
    public static var defaultOptions: PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.resizeMode = .exact
        options.version = .current
        return options
    }
}
