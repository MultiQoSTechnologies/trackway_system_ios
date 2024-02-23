//
//  UIView+Extension.swift
//  DeliveryApp
//
//  Created by MQF-6 on 06/02/24.
//

import UIKit

extension UIView {
    func setCorner(radius: CGFloat = 12) {
        self.layer.cornerRadius = radius
    }
    
    func makeCircular() {
        self.layer.cornerRadius = self.frame.height / 2
    }
    
    func setBorder(color: UIColor = .white, width: CGFloat = 1) {
        self.layer.borderColor = color.cgColor
        self.layer.borderWidth = width
    }
     
}
