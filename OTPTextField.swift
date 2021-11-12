//
//  OTPTextField.swift
//  otpviewcontroller
//


import UIKit

@objc public protocol MenuActionDelegate {
    @objc func canPerform(_ action: Selector) -> Bool
}

final class OTPTextField: UITextField {
    
    weak var menuActionDelegate: MenuActionDelegate? = nil
    
    override func caretRect(for position: UITextPosition) -> CGRect {
        return .init(origin: .init(x: self.bounds.midX, y: self.bounds.origin.y), size: .init(width: 0.1, height: 0.1))
    }
    
    override func closestPosition(to point: CGPoint) -> UITextPosition? {
        return self.endOfDocument
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(paste(_:)) ||
            action == NSSelectorFromString("pasteAndMatchStyle:") {
            return self.menuActionDelegate?.canPerform(action) ??
                super.canPerformAction(action, withSender: sender)
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
}
