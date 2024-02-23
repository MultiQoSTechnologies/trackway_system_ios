//
//  SceneDelegate+Notification.swift
//  DeliveryApp
//
//  Created by MQF-6 on 09/02/24.
//

import NotificationCenter

// MARK: - Notification Helper -
extension SceneDelegate: UNUserNotificationCenterDelegate {
    func registerForRemoteNotification() {
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: { (granted, error) in
            if (granted == true) {

            } else{
                AppPrint.print("request authorisation error: \(error?.localizedDescription ?? "")")
            }
        })
    }
    
    func sendLocalNotification(title: String, body: String, userInfo: [String: Any]) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo
         
        //UNTimeIntervalNotificationTrigger(timeInterval: 20, repeats: false)
        
        let request = UNNotificationRequest(identifier: "reminder", content: content, trigger: nil)
        center.add(request) { (error) in
            if error != nil {
                AppPrint.print("Error = \(error?.localizedDescription ?? "error local notification")")
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        AppPrint.print("======================== Did Receive Payload ===========================")
        AppPrint.print(response.notification.request.content.userInfo)
        guard let payload = response.notification.request.content.userInfo as? [String: Any] else { 
            return
        }
        handleNotificationTap(payload: payload)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        AppPrint.print("======================== Will Present Payload ===========================")
        AppPrint.print(notification.request.content.userInfo)
        guard let payload = notification.request.content.userInfo as? [String: Any] else {
            return
        }
        handleNotificationPresentation(payload: payload, completionHandler: completionHandler) 
    }
    
    private func handleNotificationTap(payload: [String: Any]) {
        
    }
    
    private func handleNotificationPresentation(payload: [String: Any], completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        guard let type = payload["type"] as? String else {
            AppPrint.print("Type not found in userInfo")
            return
        }
        
        if type == NotificationType.appTermination.rawValue {
            if Constant.user != nil {
                let mapVM = MapViewModel()
                mapVM.updateOnlineStatus(online: false)
            }
            completionHandler([])
        }
        
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .badge, .sound])
        } else {
            completionHandler([.alert, .badge, .sound])
        }
    }
    
    
}
