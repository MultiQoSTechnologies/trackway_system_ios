//
//  ViewController.swift
//  DeliveryApp
//
//  Created by MQF-6 on 06/02/24.
//

import UIKit
import DropDown
import Combine

class LoginVC: UIViewController {

    @IBOutlet weak private var viewEmail: UIView!
    @IBOutlet weak private var viewPassword: UIView!
    @IBOutlet weak private var viewRole: UIView!
    
    @IBOutlet weak private var txtEmail: UITextField!
    @IBOutlet weak private var txtPassword: UITextField!
    @IBOutlet weak private var txtRole: UITextField!
    
    @IBOutlet weak private var btnLogin: UIButton!
    
    private let dropDown = DropDown()
    private let loginVM = LoginViewModel()
    
    private var cancellables: Set<AnyCancellable> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureLoginVM()
    }
    
    
    func setupUI() {
        viewEmail.setCorner()
        viewPassword.setCorner()
        btnLogin.setCorner()
        viewRole.setCorner()
        setupDropdown()
         
    }
    
    func setupDropdown() {
        dropDown.dataSource = [Roles.User.rawValue, Roles.Driver.rawValue]
        dropDown.anchorView = btnLogin
        
        dropDown.selectionAction = { [weak self] index, value in
            guard let `self` = self else { return }
            
            self.txtRole.text = value
        }
    }
    
    func configureLoginVM() {
        loginVM.$alertMessage
            .receive(on: RunLoop.main)
            .sink { value in
                guard let string = value else { return }
                self.showToast(message: string)
            }.store(in: &cancellables)
        
        loginVM.$loginSuccess
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                guard let `self` = self else {
                    return
                }
                guard let value = value else { return }
                if value {
                    sceneDelegate.initMapView()
                }
            }.store(in: &cancellables)
    }
}


extension LoginVC {
    @IBAction private func btnRoleAction(_ sender: UIButton) {
        dropDown.show()
    }
    
    @IBAction private func btnLoginAction(_ sender: UIButton) {
        loginVM.login(email: txtEmail.text, password: txtPassword.text, role: Roles.User.rawValue == txtRole.text ?? "" ? .User : Roles.Driver.rawValue == txtRole.text ?? "" ? .Driver : .None)
    }
}

