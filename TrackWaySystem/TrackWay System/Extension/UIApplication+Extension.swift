//
//  UIApplication+Extension.swift
//  DeliveryApp
//
//  Created by MQF-6 on 06/02/24.
//

import Foundation
import NVActivityIndicatorView

let view = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40), color: .white)
let uiView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))

extension UIApplication {
    func showLoadingIndicator() {
        uiView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.type = .cubeTransition
        view.startAnimating()
        view.center = uiView.center
        uiView.addSubview(view)
        
        sceneDelegate.window?.rootViewController?.view.addSubview(uiView)
    }
    
    func hideLoadingIndicator() {
        uiView.removeFromSuperview()
        view.stopAnimating()
    }
}
