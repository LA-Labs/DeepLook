//  Copyright © 2019 la-labs. All rights reserved.

import Foundation

#if os(OSX)
import AppKit
#elseif os(iOS)
import UIKit
#endif

#if os(OSX)
public typealias UIImage = NSImage
#endif
public class Defaults {
    
    public static let shared = Defaults()
    public var print: Bool = true
    
    private init() { }
}
