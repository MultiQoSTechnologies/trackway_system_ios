//
//  ActiveDeliveryTable.swift
//  DeliveryApp
//
//  Created by MQF-6 on 06/02/24.
//

import Foundation

struct ActiveDeliveryModel: Codable { 
    var documentId: String?
    var userId: String?
    var driverId: String?
    var userLatitude: Double?
    var userLongitude: Double?
    var driverLatitude: Double?
    var driverLongitude: Double?
    var status: Int // 1. Ordered, 2. Driver Accepted, 3. Cancelled, 4. Completed
    var timestamp: Int64 = Date().currentTimeMillis()
}
