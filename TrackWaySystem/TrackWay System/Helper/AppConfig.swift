//
//  AppConfig.swift
//  DeliveryApp
//
//  Created by MQF-6 on 09/02/24.
//

import Foundation
import FirebaseRemoteConfig

struct Config: Codable {
    var NEARBY_DRIVER_SEARCH_RADIUS: Double
    var REQUEST_INTERVAL_FOR_DRIVER: Int
    
    
    init(NEARBY_DRIVER_SEARCH_RADIUS: Double = 10000, REQUEST_INTERVAL_FOR_DRIVER: Int = 10) {
        self.NEARBY_DRIVER_SEARCH_RADIUS = NEARBY_DRIVER_SEARCH_RADIUS
        self.REQUEST_INTERVAL_FOR_DRIVER = REQUEST_INTERVAL_FOR_DRIVER
    }
}
  
class AppConfig {
    static var fConfig: Config = Config()
    static private let remoteConfig = RemoteConfig.remoteConfig()
    static private let remoteConfigSetting = RemoteConfigSettings()
    
    static func listenSettingsUpdate() { 
        remoteConfig.addOnConfigUpdateListener { configUpdate, error in
            guard configUpdate != nil else {
                print("Error listening for config updates: \(error?.localizedDescription ?? "")")
                return
            }
            
            remoteConfig.activate { success, error in
                if success {
                    fConfig = try! remoteConfig.decoded(asType: Config.self)
                    AppPrint.print("Updated Config : \(fConfig.dictionary())")
                } else {
                    AppPrint.print("Active error: \(error?.localizedDescription ?? "")")
                }
            }
        }
    }
     
    static func fetchSettings() {
        remoteConfigSetting.minimumFetchInterval = 0
        remoteConfig.configSettings = remoteConfigSetting
        remoteConfig.fetchAndActivate { status, error in
            if status == .successFetchedFromRemote || status == .successUsingPreFetchedData {
                fConfig = try! remoteConfig.decoded(asType: Config.self)
                AppPrint.print("Fetched Config: \(fConfig.dictionary())")
                AppConfig.listenSettingsUpdate()
            } else {
                AppPrint.print("fetchSettings Error: \(error?.localizedDescription ?? "")")
            }
        }
    }
}
