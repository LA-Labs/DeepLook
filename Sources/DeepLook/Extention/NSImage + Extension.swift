//
//  NSImage + Extension.swift
//  LookKit
//
//  Created by Amir Lahav on 08/03/2021.
//  Copyright © 2019 la-labs. All rights reserved.

#if os(OSX)
import AppKit

extension NSImage {
    init() {
        super.init()
    }
    
    var cgImage: CGImage? {
        var proposedRect = CGRect(origin: .zero, size: size)
        
        return cgImage(forProposedRect: &proposedRect,
                       context: nil,
                       hints: nil)
    }
}
#endif
