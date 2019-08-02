//
//  CircleView.swift
//  MagicSocket
//
//  Created by Chris Zelazo on 7/31/19.
//  Copyright © 2019 Pinterest ACT. All rights reserved.
//

import UIKit

open class CircleView: UIView  {
    
    open var color: UIColor = .red {
        didSet {
            setNeedsDisplay()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    private func sharedInit() {
        backgroundColor = .clear
    }
    
    override open func draw(_ rect: CGRect) {
        let circlePath = UIBezierPath(ovalIn: rect)
        self.color.set()
        circlePath.fill()
    }
    
}
