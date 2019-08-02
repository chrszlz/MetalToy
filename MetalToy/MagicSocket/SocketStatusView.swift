//
//  SocketStatusView.swift
//  MagicSocket
//
//  Created by Chris Zelazo on 7/31/19.
//  Copyright © 2019 Pinterest ACT. All rights reserved.
//

import UIKit

public protocol SocketStatusViewDelegate {
    func socketStatusDidUpdateUrl(_ url: URL)
}

public final class SocketStatusView: UIView {
    
    public enum Status {
        case connected
        case reconnect
        case reconnectAttempt
        case disconnected
        
        public var color: UIColor {
            switch self {
            case .connected: return .green
            case .reconnect: return .green
            case .reconnectAttempt: return .yellow
            case .disconnected: return .red
            }
        }
    }
    
    public var isCollapsed: Bool = false {
        didSet {
            if animator.isRunning {
                animator.pauseAnimation()
            }
            animator.addAnimations {
                self.spacerView.isHidden = !self.isCollapsed
                self.socketAddressField.isHidden = self.isCollapsed
                
                // Fix spacing issue to make pill look normal
                let spacing = self.socketAddressField.isHidden ? 0 : self.stack.spacing
                self.stack.setCustomSpacing(spacing, after: self.dot)
                
                self.layoutIfNeeded()
            }
            animator.startAnimation()
        }
    }
    
    public var status: Status = .disconnected {
        didSet {
            dot.color = status.color
        }
    }
    
    public var host: String = "" {
        didSet {
            self.socketAddressField.text = self.host
            
            if !socketAddressField.isHidden {
                self.socketAddressField.sizeToFit()
            }
        }
    }
    
    public override var tintColor: UIColor! {
        didSet {
            socketAddressField.tintColor = tintColor
        }
    }
    
    public var delegate: SocketStatusViewDelegate?
    
    private lazy var stack: UIStackView = {
        let stack = UIStackView()
        stack.backgroundColor = .white
        stack.axis = .horizontal
        stack.spacing = 8.0
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()
    
    private lazy var dot: CircleView = {
        let dot = CircleView()
        dot.color = status.color
        return dot
    }()
    
    private let backgroundView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: effect)
        return blurView
    }()
    
    private lazy var socketAddressField: UITextField = {
        let field = UITextField()
        field.font = .monospacedDigitSystemFont(ofSize: 12.0, weight: .regular)
        field.textColor = .white
        field.textAlignment = .left
        field.clearsOnBeginEditing = false
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.keyboardAppearance = .dark
        field.returnKeyType = .done
        field.delegate = self
        return field
    }()
    
    private lazy var spacerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var tapRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer()
        recognizer.addTarget(self, action: #selector(handleTap(_:)))
        return recognizer
    }()
    
    private lazy var animator: UIViewPropertyAnimator = {
        let animator = UIViewPropertyAnimator(duration: 0.25, curve: .easeInOut, animations: nil)
        animator.isInterruptible = true
        return animator
    }()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    private func sharedInit() {
        clipsToBounds = true
        backgroundColor = .clear
        
        // Background view
        addSubview(backgroundView)
        backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        backgroundView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        
        // Stack
        let dotDimension: CGFloat = 8
        dot.widthAnchor.constraint(equalToConstant: dotDimension).isActive = true
        dot.heightAnchor.constraint(equalToConstant: dotDimension).isActive = true
        dot.translatesAutoresizingMaskIntoConstraints = false
        
        let spacerWidth: CGFloat = 6.0
        let horizontalInset: CGFloat = 12
        
        addSubview(stack)
        stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalInset).isActive = true
        stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -(horizontalInset - spacerWidth)).isActive = true
        stack.topAnchor.constraint(equalTo: topAnchor).isActive = true
        stack.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        stack.addArrangedSubview(dot)
        stack.addArrangedSubview(socketAddressField)
        
        stack.setCustomSpacing(0, after: socketAddressField)
        stack.addArrangedSubview(spacerView)
        
        spacerView.widthAnchor.constraint(equalToConstant: spacerWidth).isActive = true
        spacerView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        spacerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set height of status view with collapsed width to produce circle.
        heightAnchor.constraint(equalToConstant: dotDimension + horizontalInset * 2).isActive = true
        
        addGestureRecognizer(tapRecognizer)
        
        isCollapsed = true
        
        host = "https://www.w.w..w"
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2.0
    }
    
    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        isCollapsed = !isCollapsed
    }
    
}

extension SocketStatusView: UITextFieldDelegate {
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let socketAddress = textField.text,
            let socketUrl = URL(string: socketAddress) else {
                return true
        }
        delegate?.socketStatusDidUpdateUrl(socketUrl)
        textField.resignFirstResponder()
        return true
    }
    
}
