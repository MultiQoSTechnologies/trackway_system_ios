//
//  MapVC.swift
//  DeliveryApp
//
//  Created by MQF-6 on 06/02/24.
//

import UIKit
import GoogleMaps
import Combine
import MapKit
import Polyline

class MapVC: UIViewController {
    
    @IBOutlet weak private var mapView: GMSMapView!
    @IBOutlet weak private var navView: UIView!
    @IBOutlet weak private var driverDetailView: UIView!
    @IBOutlet weak private var lblDriver: UILabel!
    @IBOutlet weak private var lblDistance: UILabel!
    
    @IBOutlet weak private var lblTitle: UILabel!
    @IBOutlet weak private var btnSendReq: UIButton!
    
    @IBOutlet weak private var onlineView: UIView!
    @IBOutlet weak private var onlineSwitch: UISwitch!
    
    private var cancellables: Set<AnyCancellable> = []
    
    private var userOldLocation: CLLocationCoordinate2D?
    private let fromMarker = GMSMarker()
    private var arrDriverMarker = [GMSMarker]()
    private var oldCoordinate: CLLocationCoordinate2D?
    
    private var mapVM = MapViewModel()
    private var nearByDriverTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        configureMapVMListener()
        configureLocationListener()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setInitMap()        
    }
    
    private func setup() {
        lblTitle.text = Constant.user.role
        btnSendReq.setCorner()
        driverDetailView.setCorner()
        onlineSwitch.transform = CGAffineTransform(scaleX: 0.80, y: 0.80)
        
        mapVM.getActiveRide()
        
        if Constant.user.isDriver() {
            btnSendReq.tag = 1
            btnSendReq.isHidden = true
            mapVM.observeForNewRide() 
            onlineView.isHidden = false
            onlineView.setCorner(radius: 6)
            mapVM.updateOnlineStatus(online: onlineSwitch.isOn)
        } else {
            btnSendReq.tag = 0
            btnSendReq.isHidden = false
            onlineView.isHidden = true
            driverDetailView.isHidden = true
            mapVM.updateOnlineStatus(online: true)
            startNearByTimer()
        }
    }
    
    func startNearByTimer() {
        self.mapVM.getOnlineDrivers()
        nearByDriverTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { time in
            self.mapVM.getOnlineDrivers()
        }
    }
}

//  MARK: - Configure Listener
extension MapVC {
    private func mapDriversOnMap(arrDriver: [UserModel]) {
        arrDriver.forEach { [weak self] value in
            guard let `self` = self else {
                return
            }
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: value.latitude, longitude: value.longitude)
            marker.icon = .icPin.tint(with: .black)
            marker.accessibilityLabel = value.userId
            marker.map = mapView
            arrDriverMarker.append(marker)
        }
    }
    
    private func addUpdateMarkerLocation(coordinate: CLLocationCoordinate2D, marker: GMSMarker) {
        marker.position = coordinate
        marker.icon = .icPin.tint(with: .black)
        marker.map = mapView
    }
    
    private func configureMapVMListener() {
        if !Constant.user.isDriver() {
            mapVM.$arrDrivers
                .receive(on: RunLoop.main)
                .sink { [weak self] newValue in
                    guard let `self` = self else {
                        return
                    }
                    
                    if arrDriverMarker.isEmpty {
                        // No driver marker on map add all
                        mapDriversOnMap(arrDriver: newValue)
                    } else {
                        var markerIds = Set(arrDriverMarker.map{$0.accessibilityLabel ?? ""})
                        var driverIds = Set(newValue.map{$0.userId})
                        
                        if newValue.count < arrDriverMarker.count {
                            // Remove marker
                            markerIds.subtract(driverIds)
                            markerIds.forEach { id in
                                let marker = self.arrDriverMarker.filter{$0.accessibilityLabel == id}[0]
                                marker.map = nil
                                self.arrDriverMarker.removeAll(where: {$0 == marker})
                            }
                            
                        } else if newValue.count > arrDriverMarker.count {
                            // Add marker
                            driverIds.subtract(markerIds)
                            driverIds.forEach { id in
                                let driver = newValue.filter{$0.userId == id}[0]
                                let marker = GMSMarker()
                                marker.accessibilityLabel = driver.userId
                                self.arrDriverMarker.append(marker)
                                
                                self.addUpdateMarkerLocation(coordinate: CLLocationCoordinate2D(latitude: driver.latitude, longitude: driver.longitude), marker: marker)
                            }
                            
                        } else {
                            arrDriverMarker.forEach { marker in
                                newValue.forEach { driver in
                                    if marker.accessibilityLabel == driver.userId {
                                        if (driver.latitude == marker.position.latitude && driver.longitude == marker.position.longitude) {
                                            AppPrint.print("No need to update marker")
                                        } else {
                                            // Updates marker posision
                                            self.addUpdateMarkerLocation(coordinate: CLLocationCoordinate2D(latitude: driver.latitude, longitude: driver.longitude), marker: marker)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }.store(in: &cancellables)
            
            mapVM.$updateDriverLocation
                .receive(on: RunLoop.main)
                .sink { [weak self] newValue in
                    guard let `self` = self,
                          let newValue = newValue,
                          let toCoord = userOldLocation else {
                        return
                    }
                    
                    let fromCoord = newValue.coordinate
                    lblDistance.text = getDistanct(fromCoord: fromCoord, toCoord: toCoord)
                    
                    let bearing = getBearingBetweenTwoPoints1(point1: CLLocation(latitude: fromCoord.latitude, longitude: fromCoord.longitude), point2: oldCoordinate == nil ? CLLocation(latitude: 0, longitude: 0) : CLLocation(latitude: oldCoordinate!.latitude, longitude: oldCoordinate!.longitude))
                    
                    updateDriverMarker(coord: fromCoord, bearing: bearing)
                    oldCoordinate = fromCoord
                    
                    
                    updateDriverMarker(coord: fromCoord)
                }.store(in: &cancellables)
            
            mapVM.$activeRideData
                .receive(on: RunLoop.main)
                .sink { [weak self] newValue in
                    guard let `self` = self,
                          let newValue = newValue else {
                        return
                    }
                    if newValue.status == 2 {
                        // Request accepted, ride is active
                        nearByDriverTimer?.invalidate()
                        UIApplication.shared.hideLoadingIndicator()
                        driverDetailView.isHidden = false
                        btnSendReq.isHidden = true
                        
                        let fromCoord = CLLocationCoordinate2D(latitude: newValue.driverLatitude ?? 0, longitude: newValue.driverLongitude ?? 0)
                        let toCoord = CLLocationCoordinate2D(latitude: newValue.userLatitude ?? 0, longitude: newValue.userLongitude ?? 0)
                        userOldLocation = toCoord
                        
                        lblDistance.text = getDistanct(fromCoord: fromCoord, toCoord: toCoord)
                        getRoute(from: fromCoord, to: toCoord)
                        
                        guard let driverId = newValue.driverId else { return }
                        mapVM.observeUpdatedDriverLocation()
                        mapVM.getUser(id: driverId)
                        
                    } else if newValue.status == 3 {
                        // Request cancelled
                        nearByDriverTimer?.invalidate()
                        if let deleteIndex = mapVM.arrDrivers.firstIndex(where: {$0.userId == newValue.driverId}) {
                            mapVM.arrDrivers.remove(at: deleteIndex)
                            if mapVM.arrDrivers.count > 0 {
                                guard let coordinate = LocationHelper.shared.lastLocation?.coordinate else {
                                    AppPrint.print("Last Location not finding")
                                    return
                                }
                                mapVM.sendNewRequest(param: ActiveDeliveryModel(
                                    userId: Constant.user.userId,
                                    driverId: mapVM.arrDrivers.first?.userId ?? "",
                                    userLatitude: coordinate.latitude,
                                    userLongitude: coordinate.longitude,
                                    status: 1))
                            } else {
                                UIApplication.shared.hideLoadingIndicator()
                                self.showToast(message: "No neaby driver found")
                                startNearByTimer()
                            }
                        }
                        
                    } else if newValue.status == 4 {
                        // Ride completed
                        reloadUI()
                        self.showToast(message: "Voilla... Ride completed successfully.")
                    }
                    
                    AppPrint.print("Changes observed : \(newValue.status )")
                }.store(in: &cancellables)
            
        } else {
            mapVM.$activeRideData
                .receive(on: RunLoop.main)
                .sink { [weak self] newValue in
                    guard let `self` = self,
                          let newValue = newValue else {
                        return
                    }
                    if newValue.status == 1 {
                        // New Request came
                        presentAcceptRejectView(newReqReceived: newValue)
                    } else if newValue.status == 2 {
                        // Request accepted, ride is active
                        let toLoc = CLLocationCoordinate2D(latitude: newValue.userLatitude ?? 0, longitude: newValue.userLongitude ?? 0)
                        guard let fromLoc = LocationHelper.shared.lastLocation?.coordinate else { return }
                        showCompleteRide(from: fromLoc, to: toLoc)
                        
                    } else if newValue.status == 3 {
                        // Request cancelled
                        
                    } else if newValue.status == 4 {
                        // Ride completed
                        
                    }
                }.store(in: &cancellables)
             
        }
        
        mapVM.$remoteUserData
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                guard let `self` = self else {
                    return
                }
                lblDriver.text = newValue?.email
                
            }.store(in: &cancellables)
    }
    
    private func configureLocationListener() {
        LocationHelper.shared.$lastLocation
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                guard let `self` = self else {
                    return
                }
                guard let coordinate = newValue?.coordinate else { return }
                
                if Constant.user.isDriver() {
                    mapVM.updateLocationInUserTable(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    
                    let bearing = getBearingBetweenTwoPoints1(point1: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude), point2: oldCoordinate == nil ? CLLocation(latitude: newValue?.coordinate.latitude ?? 0, longitude: newValue?.coordinate.longitude ?? 0) : CLLocation(latitude: oldCoordinate!.latitude, longitude: oldCoordinate!.longitude))
                    
                    updateDriverMarker(coord: coordinate, bearing: bearing)
                    oldCoordinate = coordinate
                    
                } else {
                    mapVM.updateLocationInUserTable(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    LocationHelper.shared.stopMornitoring()
                }
            }.store(in: &cancellables)
    }
}

extension MapVC {
    private func presentAcceptRejectView(newReqReceived: ActiveDeliveryModel) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "AcceptRejectVC") as? AcceptRejectVC else {
            return
        }
        vc.modalPresentationStyle = .overCurrentContext
        vc.newReqReceived = newReqReceived
        vc.mapVM = mapVM
        vc.callback = { [weak self] in 
            guard let `self` = self,
                  let fromCoordinate = LocationHelper.shared.lastLocation?.coordinate,
                  let destinationLoc = mapVM.activeRideData  else {
                return
            }
            
            let toCordinate = CLLocationCoordinate2D(latitude: destinationLoc.userLatitude ?? 0, longitude: destinationLoc.userLongitude ?? 0)
            
            showCompleteRide(from: fromCoordinate, to: toCordinate)
        }
        present(vc, animated: true)
    }
    
    func showCompleteRide(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        getRoute(from: from, to: to)
        btnSendReq.isHidden = false
        btnSendReq.setTitle("Complete Ride", for: .normal)
    }
    
    private func reloadUI() {
        self.setInitMap()
        setup()
    }
}

// MARK: - Actions -
extension MapVC {
    @IBAction private func switchValueChange(_ sender: UISwitch) {
        mapVM.updateOnlineStatus(online: sender.isOn)
    }
    @IBAction private func btnSendReqAction(_ sender: UIButton) {
        if sender.tag == 0 {
            guard let coordinate = LocationHelper.shared.lastLocation?.coordinate else {
                AppPrint.print("Last Location not finding")
                return
            }
            guard let firstDriver = mapVM.arrDrivers.first else {
                AppPrint.print("No Driver Found")
                return
            }
            
            mapVM.sendNewRequest(param: ActiveDeliveryModel(
                        userId: Constant.user.userId,
                        driverId: firstDriver.userId,
                        userLatitude: coordinate.latitude,
                        userLongitude: coordinate.longitude,
                        status: 1)
            )
            nearByDriverTimer?.invalidate()
        } else {
            mapVM.updateRideStatus(status: 4)
            reloadUI()
        }
    }
}

 
//  MARK: - Map Helper
extension MapVC {
    private func setInitMap() {
        guard let location = LocationHelper.shared.lastLocation else { return }
        let marker: GMSMarker = GMSMarker()
        marker.appearAnimation = .pop
        marker.position = location.coordinate
        marker.icon = .icCurrent.tint(with: .black)
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            mapView.clear()
            marker.map = mapView
            
            let camPosition = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 16)
            mapView.camera = camPosition
            CATransaction.begin()
            CATransaction.setValue(5.0, forKey: kCATransactionAnimationDuration)
            self.mapView.animate(to: camPosition)
            CATransaction.commit()
        }
    }
    
    private func getDistanct(fromCoord: CLLocationCoordinate2D, toCoord: CLLocationCoordinate2D) -> String {
        let measurement = Measurement(value: CLLocation(latitude: fromCoord.latitude, longitude: fromCoord.longitude).distance(from: CLLocation(latitude: toCoord.latitude, longitude: toCoord.longitude)).round(to: 2), unit: UnitLength.meters).converted(to: .kilometers)

        let mf = MeasurementFormatter()
        mf.unitOptions = .providedUnit
        mf.unitStyle = .medium
        mf.numberFormatter.maximumFractionDigits = 1
        
        return mf.string(from: measurement)   // "0.1 km"
    }
    
    private func getRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        let source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: to))

        let request = MKDirections.Request()
        request.source = source
        request.destination = destination
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)

        directions.calculate(completionHandler: { (response, error) in
            if let res = response {
                self.show(polyline: self.googlePolylines(from: res), from: from, to: to)
            }
        })
    }
    
    private func googlePolylines(from response: MKDirections.Response) -> GMSPolyline {
        let route = response.routes[0]
        var coordinates = [CLLocationCoordinate2D](
            repeating: kCLLocationCoordinate2DInvalid,
            count: route.polyline.pointCount)

        route.polyline.getCoordinates(
            &coordinates,
            range: NSRange(location: 0, length: route.polyline.pointCount))

        let polyline = Polyline(coordinates: coordinates)
        let encodedPolyline: String = polyline.encodedPolyline
        let path = GMSPath(fromEncodedPath: encodedPolyline)
        return GMSPolyline(path: path)
    }
    
    private func updateDriverMarker(coord: CLLocationCoordinate2D, bearing: Double = 0) {
        if bearing != 0 {
            CATransaction.begin()
            CATransaction.setValue(2.0, forKey: kCATransactionAnimationDuration)
            CATransaction.setCompletionBlock {
                self.fromMarker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
            }
            fromMarker.icon = .icPin.tint(with: .black)
            fromMarker.rotation = bearing
            self.mapView.animate(to: GMSCameraPosition.camera(withLatitude: coord.latitude, longitude: coord.longitude, zoom: 15))
            self.fromMarker.position = CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
            self.fromMarker.map = self.mapView
            CATransaction.commit()
        }
    }
    
    private func degreesToRadians(degrees: Double) -> Double { return degrees * .pi / 180.0 }
    
    private func radiansToDegrees(radians: Double) -> Double { return radians * 180.0 / .pi }

    private func getBearingBetweenTwoPoints1(point1 : CLLocation, point2 : CLLocation) -> Double {

        let lat1 = degreesToRadians(degrees: point1.coordinate.latitude)
        let lon1 = degreesToRadians(degrees: point1.coordinate.longitude)

        let lat2 = degreesToRadians(degrees: point2.coordinate.latitude)
        let lon2 = degreesToRadians(degrees: point2.coordinate.longitude)

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)

        return radiansToDegrees(radians: radiansBearing)
    }
    
    private func show(polyline: GMSPolyline, from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        mapView.clear()
        
        fromMarker.position = from
        fromMarker.icon = .icPin.tint(with: .black)
        fromMarker.map = mapView
        
        let toMarker = GMSMarker(position: to)
        toMarker.icon = .icPinDrop.tint(with: .black)
        toMarker.map = mapView
         
        polyline.strokeColor = .theme.withAlphaComponent(0.8)
        polyline.strokeWidth = 4
        //add to map
        polyline.map = mapView
        
        // Test changes
        
        let bounds = GMSCoordinateBounds(coordinate: from, coordinate: to)
        let camera = mapView.camera(for: bounds, insets: UIEdgeInsets(top: 30, left: 40, bottom: 30, right: 40))!
        CATransaction.begin()
        CATransaction.setValue(2.0, forKey: kCATransactionAnimationDuration)
        self.mapView.animate(to: camera)
        CATransaction.commit()
    }
}
