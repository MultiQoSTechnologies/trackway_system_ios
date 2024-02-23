//
//  UIViewController+Extension.swift
//  DeliveryApp
//
//  Created by MQF-6 on 06/02/24.
//

import UIKit
import Toast_Swift
import NVActivityIndicatorView

extension UIViewController {
    func showToast(message: String) { 
        self.view.makeToast(message)
    }
    
    @IBAction func backAction() {
        self.navigationController?.popViewController(animated: true)
    }
}

