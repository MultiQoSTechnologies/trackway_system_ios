//
//  UserModel.swift
//  DeliveryApp
//
//  Created by MQF-6 on 06/02/24.
//

import Foundation
import FirebaseFirestore

struct UserModel : Codable {
    
    let email : String?
    let isOnline : Bool?
    let latitude : Double
    let longitude : Double
    let name : String?
    let role : String?
    let userId : String
    let geohash : String

    enum CodingKeys: String, CodingKey {
        case email = "email"
        case isOnline = "isOnline"
        case latitude = "latitude"
        case longitude = "longitude"
        case name = "name"
        case role = "role"
        case userId = "userId"
        case geohash = "geohash"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        email = try values.decodeIfPresent(String.self, forKey: .email)
        isOnline = try values.decodeIfPresent(Bool.self, forKey: .isOnline)
        latitude = try values.decodeIfPresent(Double.self, forKey: .latitude) ?? 0
        longitude = try values.decodeIfPresent(Double.self, forKey: .longitude) ?? 0
        name = try values.decodeIfPresent(String.self, forKey: .name)
        role = try values.decodeIfPresent(String.self, forKey: .role)
        userId = try values.decodeIfPresent(String.self, forKey: .userId) ?? ""
        geohash = try values.decodeIfPresent(String.self, forKey: .geohash) ?? ""
    }
    
    init(email: String? = nil, isOnline: Bool? = nil, latitude: Double? = nil, longitude: Double? = nil, name: String? = nil, role: String? = nil, userId: String, geohash: String) {
        self.email = email
        self.isOnline = isOnline
        self.latitude = latitude ?? 0
        self.longitude = longitude ?? 0
        self.name = name
        self.role = role
        self.userId = userId
        self.geohash = geohash
    }
    
    func isDriver() -> Bool {
        return role == Roles.Driver.rawValue ? true : false
    }
}
