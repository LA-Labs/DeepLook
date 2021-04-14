//
//  VisionProcessError.swift
//  
//
//  Created by Amir Lahav on 29/01/2021.
//  Copyright © 2019 la-labs. All rights reserved.

import Foundation

public enum VisionProcessError: Error {
    
    case unknown
    case fetchImages
    case facesDetecting
    case cgImageNotFound
    case emptyObservation
    case error(Error)
    var description: String {
        switch self {
        case .fetchImages:
            return "Cannot fetch this image"
        case .facesDetecting:
            return "Unable to detect faces"
        case .cgImageNotFound:
            return "CGImage not found"
        case .emptyObservation:
            return "No faces found"
        case .unknown:
            return "Unknown error"
        case .error(let error):
        return error.localizedDescription
        }
    }
}
