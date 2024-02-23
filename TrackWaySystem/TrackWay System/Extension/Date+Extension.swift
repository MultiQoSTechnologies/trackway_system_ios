//
//  Date+Extension.swift
//  DeliveryApp
//
//  Created by MQF-6 on 06/02/24.
//

import Foundation

extension Date {
    func currentTimeMillis() -> Int64 {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
}
