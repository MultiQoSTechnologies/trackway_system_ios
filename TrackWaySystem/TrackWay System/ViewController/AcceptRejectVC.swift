//
//  AcceptRejectVC.swift
//  DeliveryApp
//
//  Created by MQF-6 on 07/02/24.
//

import UIKit
import Combine

class AcceptRejectVC: UIViewController {
    
    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var lblUserName: UILabel!
    @IBOutlet weak private var lblAddress: UILabel!
    @IBOutlet weak private var lblAcceptTimer: UILabel!
    @IBOutlet weak private var btnAccept: UIButton!
    @IBOutlet weak private var btnReject: UIButton!
    @IBOutlet weak var viewTopImage: UIView!
    
    
    
    var callback: (() -> Void)?
    var newReqReceived: ActiveDeliveryModel?
    var mapVM: MapViewModel = MapViewModel()
    
    private var cancellables: Set<AnyCancellable> = []
    private var acceptRejectTimer: Timer?
    private var acceptRejectTimerCount: Int = AppConfig.fConfig.REQUEST_INTERVAL_FOR_DRIVER //AppConfig.REQUEST_INTERVAL_FOR_DRIVER
       
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        confinureMapViewModelListener()
        configureLocationListener()
    }

    private func setup() {
        btnAccept.setCorner(radius: 8)
        btnReject.setCorner(radius: 8)
        mainView.setCorner(radius: 30)
        viewTopImage.makeCircular()
        
        guard let userId = newReqReceived?.userId else { return }
        mapVM.getUser(id: userId)
        configureTimer()
    }
    
    private func configureTimer() {
        acceptRejectTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let `self` = self else {
                return
            }
            acceptRejectTimerCount = acceptRejectTimerCount - 1
            self.lblAcceptTimer.text = "\(acceptRejectTimerCount)"
            if acceptRejectTimerCount == 0 {
                btnRejectAction(btnReject as Any)
            }
        }
    }
}

//  MARK: - Configure Listener -
extension AcceptRejectVC {
    private func confinureMapViewModelListener() {
        mapVM.$remoteUserData
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                guard let `self` = self,
                      let newValue = newValue,
                      let newReqReceived = mapVM.activeRideData
                      else {
                    return
                }
                lblUserName.text = newValue.email
                LocationHelper.shared.getAddressFrom(lat: newReqReceived.userLatitude ?? 0, lon: newReqReceived.userLongitude ?? 0)
            }.store(in: &cancellables)
    }
    
    private func configureLocationListener() {
        LocationHelper.shared.$addressString
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                guard let `self` = self,
                      let newValue = newValue else {
                    return
                }
                lblAddress.text = newValue
            }.store(in: &cancellables)
    }
}

//  MARK: - Actions-
extension AcceptRejectVC {
    @IBAction func btnBackgroundAction(_ sender: Any) {
//        dismiss(animated: true)
    }
    
    @IBAction func btnRejectAction(_ sender: Any) {
        mapVM.updateRideStatus(status: 3)
        acceptRejectTimer?.invalidate()
        dismiss(animated: true)
    }
    
    @IBAction func btnAcceptAction(_ sender: Any) { 
        let param: [String: Any] = [
            "status": 2,
            "driverLatitude": LocationHelper.shared.lastLocation?.coordinate.latitude ?? 0,
            "driverLongitude": LocationHelper.shared.lastLocation?.coordinate.longitude ?? 0
        ]
        mapVM.updateActiveRideData(param: param)
        acceptRejectTimer?.invalidate()
        callback?()
        dismiss(animated: true)
    }
}
