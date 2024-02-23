//
//  LoginViewModel.swift
//  DeliveryApp
//
//  Created by MQF-6 on 06/02/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import GeoFire

class LoginViewModel {
    @Published var alertMessage: String?
    @Published var loginSuccess: Bool?
    private var auth = Auth.auth()
    private var firestore = Firestore.firestore()
}

extension LoginViewModel {
    func login(email: String?, password: String?, role: Roles) {
        guard let email = email, email != "" else {
            alertMessage = AppMessages.enterEmail
            return
        }
        
        guard email.isValidEmail() else {
            alertMessage = AppMessages.enterValidEmail
            return
        }
        
        guard let password = password, password != "" else {
            alertMessage = AppMessages.enterPassword
            return
        }
        
        guard password.count >= 6 else {
            alertMessage = AppMessages.passwordLength
            return
        }
        
        guard role != .None else {
            alertMessage = AppMessages.selectRole
            return
        }
        
        authLogin(email: email, password: password, role: role)
        
    }
     
    private func authLogin(email: String, password: String, role: Roles) {
        UIApplication.shared.showLoadingIndicator()
        
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let `self` = self else {
                return
            }
            
            if error == nil {
                UIApplication.shared.hideLoadingIndicator()
                if let result = result {
                    setUserData(result: result, role: role.rawValue)
                    loginSuccess = true
                }
            } else {
                UIApplication.shared.hideLoadingIndicator()
                
                if let error = error as NSError? {
                    let authError = AuthErrorCode(_nsError: error).code
                    switch authError {
                    case .invalidEmail:
                        AppPrint.print("invalid email")
                    
                    case .userNotFound:
                        AppPrint.print("userNotFound")
                         
                    case .internalError:
                        UIApplication.shared.showLoadingIndicator()
                        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
                            guard let `self` = self else {
                                return
                            }
                            UIApplication.shared.hideLoadingIndicator()
                            if error == nil {
                                if let result = result {
                                    setUserData(result: result, role: role.rawValue)
                                    loginSuccess = true
                                }
                            } else {
                                if let error = error as NSError? {
                                    let authError = AuthErrorCode(_nsError: error).code
                                    switch authError {
                                    case .invalidEmail:
                                        AppPrint.print("invalid email")
                                    case .emailAlreadyInUse:
                                        AppPrint.print("in use")
                                    default:
                                        AppPrint.print("Other error!")
                                    }
                                }
                            }
                        }
                        
                    default:
                        AppPrint.print("Other error!")
                    }
                }
            }
        }
    }
    
    private func setUserData(result: AuthDataResult, role: String) {
        let user = result.user
        let coord = LocationHelper.shared.lastLocation?.coordinate
        let model = UserModel(email: user.email ?? "", latitude: coord?.latitude ?? 0, longitude: coord?.longitude ?? 0, name: user.displayName ?? "", role: role, userId: user.uid, geohash: GFUtils.geoHash(forLocation: coord ?? CLLocationCoordinate2D()))
        do {
            try UserDefaults.standard.set<UserModel>(object: model.self, forKey: "User")
            firestore.collection(FICollectionName.user.rawValue).document(model.userId).setData(model.dictionary())
            Constant.user = model
        } catch let error {
            AppPrint.print("Store error : \(error.localizedDescription)")
        }
    }
}



