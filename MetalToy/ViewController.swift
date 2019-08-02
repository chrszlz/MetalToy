//
//  ViewController.swift
//  MetalToy
//
//  Created by Chris Zelazo on 7/31/19.
//  Copyright © 2019 Chris Zelazo. All rights reserved.
//

import UIKit
import SnapKit

class ViewController: UIViewController {

    private lazy var metalView = MetalView()
    
    private lazy var statusView = SocketStatusView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(metalView)
        metalView.snp.makeConstraints {
            $0.width.equalTo(self.view)
            $0.height.equalTo(self.view)
            $0.center.equalTo(self.view)
        }
        
        view.addSubview(statusView)
        statusView.snp.makeConstraints {
            $0.topMargin.equalTo(self.view).inset(18)
            $0.leftMargin.equalTo(self.view).inset(18)
        }
    }


}

