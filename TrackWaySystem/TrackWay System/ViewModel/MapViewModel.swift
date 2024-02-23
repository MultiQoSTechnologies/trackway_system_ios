//
//  MapViewModel.swift
//  DeliveryApp
//
//  Created by MQF-6 on 06/02/24.
//

import Foundation
import FirebaseFirestore
import CoreLocation
import GeoFire

class MapViewModel {
    private let firestore = Firestore.firestore()
    
    private var lastOrderId: String?
    
    @Published var arrDrivers = [UserModel]()
    @Published var activeRideData: ActiveDeliveryModel?
    @Published var remoteUserData: UserModel?
    @Published var driverData: UserModel?
    @Published var updateDriverLocation: CLLocation?
}

//  MARK: - Set Methods -
extension MapViewModel {
    func sendNewRequest(param: ActiveDeliveryModel) {
        UIApplication.shared.showLoadingIndicator()
        
        let ref = firestore
            .collection(FICollectionName.activeDelivery.rawValue)
            .document()
        
        lastOrderId = ref.documentID
        
        ref.setData(param.dictionary())
        observeChangeInOrder()
    }
}

//  MARK: - Get Methods -
extension MapViewModel {
    func getAllUsers() {
        firestore
            .collection(FICollectionName.user.rawValue)
            .getDocuments { qsnap, error in
                guard let qsnap  = qsnap else {
                    AppPrint.print("Error in getting users: \(error?.localizedDescription ?? "")")
                    return
                }
                
                qsnap.documents.forEach { snap in
                    let userData: UserModel! = snap.data().castToObject()
                    AppPrint.print("Offline user data: \(userData.userId)")
                }
            }
    }
    
    func addNewUser() {
        let docRef = firestore
            .collection(FICollectionName.user.rawValue)
            .document("testuser")
        docRef
            .setData([
                "email": "umang7@yopmail.com",
                "geohash": "9q9hrhds7p",
                "isOnline": false,
                "latitude": 37.335062,
                "longitude": -122.032570,
                "name": "test",
                "role": "Driver",
                "userId": "testuser",
            ])
    }
    func getActiveRide() {
        firestore
            .collection(FICollectionName.activeDelivery.rawValue)
            .whereField("status", isEqualTo: 2)
            .getDocuments { [weak self] qsnapshot, error in
                guard let `self` = self else {
                    return
                }
                
                if error == nil {
                    let dict = qsnapshot?.documents.map{$0.data()}.first
                    if dict != nil {
                        activeRideData = qsnapshot?.documents.map{$0.data()}.first?.castToObject()
                        activeRideData?.documentId = qsnapshot?.documents.first?.documentID
                        lastOrderId = activeRideData?.documentId
                        observeChangeInOrder()
                    } else {
                        AppPrint.print("User does not have any active ride")
                    }
                }
            }
    }
    
    func getUser(id: String, isForStatusCheck: Bool = false) {
        firestore
            .collection(FICollectionName.user.rawValue)
            .whereField("userId", isEqualTo: id)
            .getDocuments { [weak self] qsnapshot, error in
                guard let `self` = self else {
                    return
                }
                
                if error == nil {
                    let model: UserModel? = qsnapshot?.documents.first?.data().castToObject()
                    remoteUserData = model
                    
                    if isForStatusCheck {
                        driverData = model
                    }
                }
            }
    }
    
    func getOnlineDrivers() {
        guard let coordinates = LocationHelper.shared.lastLocation?.coordinate else {
            return
        }
        
        let queryBounds = GFUtils.queryBounds(
            forLocation: coordinates,
            withRadius: AppConfig.fConfig.NEARBY_DRIVER_SEARCH_RADIUS) // AppConfig.NEARBY_DRIVER_SEARCH_RADIUS
        let _ = queryBounds
            .map { bound in
                return firestore
                    .collection(FICollectionName.user.rawValue)
                    .order(by: "geohash")
                    .start(at: [bound.startValue])
                    .end(at: [bound.endValue])
                    .whereField("role", isEqualTo: Roles.Driver.rawValue)
                    .whereField("isOnline", isEqualTo: true)
                    .getDocuments { qsnapshot, error in
                        if error == nil {
                            qsnapshot.map { [weak self] sp in
                                guard let `self` = self else {
                                    return
                                }
                                for doc in sp.documents {
                                    let lat = doc["latitude"] as? Double ?? 0
                                    let long = doc["longitude"] as? Double ?? 0
                                    let toCoors = CLLocation(latitude: lat, longitude: long)
                                    let distance = GFUtils.distance(from: CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude), to: toCoors)
                                    if distance <= AppConfig.fConfig.NEARBY_DRIVER_SEARCH_RADIUS {
                                        let model: UserModel? = doc.data().castToObject()
                                        guard let model = model else { return }
                                        arrDrivers.append(model)
                                        arrDrivers = arrDrivers.unique(map: {$0.userId})
                                        AppPrint.print("Found total drivers: \(arrDrivers.count)")
                                    }
                                }
                            }
                        }
                    }
            }
    }
}

//  MARK: - Update Methods -
extension MapViewModel {
    func updateRideStatus(status: Int) {
        guard let documentId = activeRideData?.documentId else {
            AppPrint.print("newReqDocId not found")
            return
        }
        firestore
            .collection(FICollectionName.activeDelivery.rawValue)
            .document(documentId)
            .updateData(["status": status])
    }
    
    func updateLocationInUserTable(latitude: Double, longitude: Double) {
        firestore
            .collection(FICollectionName.user.rawValue)
            .document(Constant.user.userId)
            .updateData(["latitude": latitude, "longitude": longitude, "geohash": GFUtils.geoHash(forLocation: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))])
    }
    
    func updateActiveRideData(param: [String: Any]) {
        guard let documentId = activeRideData?.documentId else {
            AppPrint.print("DocumentID not found")
            return
        }
        firestore
            .collection(FICollectionName.activeDelivery.rawValue)
            .document(documentId)
            .updateData(param)
    }
    
    func updateOnlineStatus(online: Bool) {
        firestore
            .collection(FICollectionName.user.rawValue)
            .document(Constant.user.userId)
            .updateData(["isOnline": online])
    }
}

//  MARK: - Observers Methods -
extension MapViewModel {
    func observeForNewRide() {
        firestore
            .collection(FICollectionName.activeDelivery.rawValue)
            .whereField("driverId", isEqualTo: Constant.user.userId)
            .whereField("status", isEqualTo: 1)
            .addSnapshotListener { [weak self] qsnapshot, error in
                guard let `self` = self else {
                    return
                }
                
                if error == nil {
                    guard let data = qsnapshot?.documents.map({$0.data()}).first else  {
                        return
                    }
                    activeRideData = data.castToObject()
                    activeRideData?.documentId = qsnapshot?.documents.first?.documentID
//                    newReqDocId = qsnapshot?.documents.first?.documentID
                }
            }
    }
    
    func observeChangeInOrder() {
        guard let lastOrderId = lastOrderId else {
            AppPrint.print("lastOrderId is nil")
            return
        }
        firestore
            .collection(FICollectionName.activeDelivery.rawValue)
            .document(lastOrderId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let `self` = self else {
                    return
                }
                if error == nil {
                    guard let snapshot = snapshot else { return }
                    
                    guard let model: ActiveDeliveryModel = snapshot.data()?.castToObject() else {
                        AppPrint.print("Not getting ActiveDeliveryModel")
                        return
                    }
                    
                    activeRideData = model
                } else {
                    AppPrint.print("Error in observation: \(error?.localizedDescription ?? "")")
                }
            }
    }
    
    func observeUpdatedDriverLocation() {
        guard let activeRideData = activeRideData else { return }
        firestore
            .collection(FICollectionName.user.rawValue)
            .whereField("userId", isEqualTo: activeRideData.driverId ?? "")
            .addSnapshotListener { [weak self] qsnapshot, error in
                if error == nil {
                    guard let `self` = self,
                          let data = qsnapshot?.documents.first?.data() else {
                        AppPrint.print("Unable to get data")
                        return
                    }
                    let latitude = data["latitude"] as? Double ?? 0
                    let longitude = data["longitude"] as? Double ?? 0
                    self.updateDriverLocation = CLLocation(latitude: latitude, longitude: longitude)
                }
            }
    }
}
