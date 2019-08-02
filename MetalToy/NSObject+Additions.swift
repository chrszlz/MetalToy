//
//  NSObject+Additions.swift
//  MetalToy
//
//  Created by Chris Zelazo on 7/31/19.
//  Copyright © 2019 Chris Zelazo. All rights reserved.
//

import Foundation

public extension NSObjectProtocol {
    
    /// Makes the receiving value accessible within the passed block parameter.
    /// - parameter block: Closure executing a given task on the receiving function value.
    func setUp(_ block: (Self)->Void) {
        block(self)
    }
    
    /// Makes the receiving value accessible within the passed block parameter and ends up returning the modified value.
    /// - parameter block: Closure executing a given task on the receiving function value.
    /// - returns: The modified value
    func set(_ block: (Self)->Void) -> Self {
        block(self)
        return self
    }
    
}
