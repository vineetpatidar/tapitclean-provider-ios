

import UIKit
import SideMenu
import FirebaseMessaging
import CoreLocation
import FBSDKCoreKit
import SVProgressHUD

class HomeViewController: BaseViewController,Storyboarded, CLLocationManagerDelegate {
    
    
    @IBOutlet weak var taskInday: UILabel!
    @IBOutlet weak var taskinWeek: UILabel!
    @IBOutlet weak var taskStatus: UILabel!
    @IBOutlet weak var viewTask: UIView!
    @IBOutlet weak var taskButton: UIButton!
    @IBOutlet weak var bgView: UIView!
    
    var locationManager : CLLocationManager?
    
    var appDelegate : AppDelegate?
    var coordinator: MainCoordinator?
    var viewModel : HomeViewModal = {
        let viewModel = HomeViewModal()
        return viewModel }()
    
    deinit {
//        SKPaymentQueue.default().remove(SubscriptionManager.shared)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        self.setNavWithOutView(ButtonType.menu)
        viewTask.layer.borderWidth = 5
        viewTask.layer.borderColor = hexStringToUIColor("C1E6B2").cgColor
        viewTask.clipsToBounds = true
        
        SideMenuManager.default.leftMenuNavigationController = storyboard?.instantiateViewController(withIdentifier: "LeftMenuNavigationController") as? SideMenuNavigationController
        SideMenuManager.default.addPanGestureToPresent(toView: navigationController!.navigationBar)
        SideMenuManager.default.addScreenEdgePanGesturesToPresent(toView: view)
        coordinator = MainCoordinator(navigationController: self.navigationController!)
        AppEvents.shared.logEvent(.subscribe)
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "Vineet event"))
        
        // Set the delegate to receive subscription manager callbacks
        SubscriptionManager.shared.delegate = self
        SubscriptionManager.shared.purchaseDelegate = self
    }
    
    @objc private func onShowLocationAlert(_ note: Notification) {
        // update UI / state
        self.showLocationAlert()
    }
    
    func showLocationAlert(){
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Allow Location Access", message: "Provider App needs access to your location. Turn on Location Services in your device settings.", preferredStyle: UIAlertController.Style.alert)
            // Button to Open Settings
            alert.addAction(UIAlertAction(title: "Settings", style: UIAlertAction.Style.default, handler: { action in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        print("Settings opened: \(success)")
                    })
                }
            }))
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onShowLocationAlert(_:)),
            name: .showLocaitonAlert,
            object: nil
        )
        self.getDriverInfo() // get drive info
//        if((CurrentUserInfo.latitude == "0" || CurrentUserInfo.latitude == nil) && CurrentUserInfo.dutyStarted){
//            let appDelegate = UIApplication.shared.delegate as? AppDelegate
//            let status = CLLocationManager.authorizationStatus()
//            switch status {
//            case .notDetermined:
//                if(locationManager != nil){
//                    locationManager?.stopUpdatingLocation()
//                    locationManager = nil
//                }
//                locationManager = CLLocationManager()
//                locationManager?.delegate = self
//                locationManager?.requestAlwaysAuthorization()
////                appDelegate?.setupLocationManager()
//            case .restricted, .denied:
//                showLocationAlert()
//                break
//            case .authorizedWhenInUse,.authorizedAlways:
//                appDelegate?.setupLocationManager()
//                appDelegate?.startGPSTraking()
//                break
//            default:
//                break
//            }
//        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func taskButtonAction(_ sender: Any) {
        
        let currentDate = Date()
        let timestampInSeconds = Int(currentDate.timeIntervalSince1970)
        
        if (CurrentUserInfo.subscriptionEndDate < timestampInSeconds){
            showSubscriptionBottomSheet()
        }
        else{
            if(CurrentUserInfo.dutyStarted  == false){
                let status = CLLocationManager.authorizationStatus()
                switch status {
                case .notDetermined:
                    if(locationManager != nil){
                        locationManager?.stopUpdatingLocation()
                        locationManager = nil
                    }
                    locationManager = CLLocationManager()
                    locationManager?.delegate = self
                    locationManager?.requestAlwaysAuthorization()
                case .restricted, .denied:
                    showLocationAlert()
                    break
                case .authorizedWhenInUse,.authorizedAlways:
                    self.appDelegate?.setupLocationManager()
                    self.startDutyAction()
                    break
                default:
                    break
                }
            }
            else{
                self.startDutyAction()
            }
        }
        

        

    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted, .denied:
            locationManager?.stopUpdatingLocation()
            locationManager = nil
            showLocationAlert()
            break
        case .authorizedWhenInUse,.authorizedAlways:
            locationManager?.stopUpdatingLocation()
            locationManager = nil
            self.appDelegate?.setupLocationManager()
            self.startDutyAction()
            break
        default:
            break
        }
        
        
    }
    
    func startDutyAction(){
        
        let title = CurrentUserInfo.dutyStarted == false ? "MAKE ME AVAILABLE" : "MAKE ME UNAVAILABLE"
        let msg = CurrentUserInfo.dutyStarted  == false ? "Are you ready to start your duty?" : "Are you sure to end your duty?"
        let btnText = CurrentUserInfo.dutyStarted  == false  ? "Yes, Start" :"Yes, End"
        let color = CurrentUserInfo.dutyStarted  == false ? kAlertGreen :kAlertRed

        AlertWithAction(title:title, message: msg, [btnText,"No"], vc: self, color) { action in
            if(action == 1){
                self.viewModel.startDuty(CurrentUserInfo.dutyStarted ? APIsEndPoints.driverEnd.rawValue : APIsEndPoints.driverStart.rawValue, self.viewModel.dictInfo, handler: {[weak self](result,statusCode)in
                    if statusCode ==  0{
                        DispatchQueue.main.async {
                            let appDelegate = UIApplication.shared.delegate as? AppDelegate
                            
                            if(CurrentUserInfo.dutyStarted == true){
                                self?.taskButton.backgroundColor = hexStringToUIColor("000000")
                                self?.taskButton.setTitle("MAKE ME AVAILABLE", for: .normal)
                                CurrentUserInfo.dutyStarted = false
                                appDelegate?.stopLocationManager()
                            }else{
                                self?.taskButton.backgroundColor = hexStringToUIColor("FA2A2A")
                                self?.taskButton.setTitle("MAKE ME UNAVAILABLE", for: .normal)
                                CurrentUserInfo.dutyStarted = true
                                appDelegate?.startGPSTraking()
                            }
                        }
                    }
                })
                
            }
        }
    }
    
    func getDriverInfo(){
        self.viewModel.getUserData(APIsEndPoints.userProfile.rawValue , self.viewModel.dictInfo, handler: {[weak self](result,statusCode)in
            if statusCode ==  0{
                self?.bgView.isHidden = false
                DispatchQueue.main.async {
                    CurrentUserInfo.userId = result.driverId
                    CurrentUserInfo.userName = result.fullName
                    CurrentUserInfo.email = result.email
                    CurrentUserInfo.phone = result.phoneNumber
                    CurrentUserInfo.vehicleNumber = result.vehicleNumber
                    CurrentUserInfo.profileUrl = result.profileImage
                    CurrentUserInfo.subscriptionEndDate = result.subscriptionEndDate
                    CurrentUserInfo.subscriptionType = result.subscriptionType
                    CurrentUserInfo.totalCredit = result.totalCredit
                    
                    Messaging.messaging().subscribe(toTopic: CurrentUserInfo.userId) { error in
                        if let error = error {
                            print("Error subscribing from topic: \(error.localizedDescription)")
                        } else {
                            print("Successfully subscribed from topic!")
                        }
                    }
                    
                    self?.taskinWeek.text = "\(result.requestInWeek ?? 0)"
                    self?.taskInday.text = "\(result.requestInDay ?? 0)"
                    
                    if(result.dutyStarted ?? false){
                        let appDelegate = UIApplication.shared.delegate as? AppDelegate
                        let status = CLLocationManager.authorizationStatus()
                        switch status {
                        case .notDetermined:
                            if(self?.locationManager != nil){
                                self?.locationManager?.stopUpdatingLocation()
                                self?.locationManager = nil
                            }
                            self?.locationManager = CLLocationManager()
                            self?.locationManager?.delegate = self
                            self?.locationManager?.requestAlwaysAuthorization()
                        case .restricted, .denied:
                            self?.showLocationAlert()
                            break
                        case .authorizedWhenInUse,.authorizedAlways:
                            self?.taskButton.backgroundColor = hexStringToUIColor("FA2A2A")
                            self?.taskButton.setTitle("MAKE ME UNAVAILABLE", for: .normal)
                            CurrentUserInfo.dutyStarted = true
                            appDelegate?.setupLocationManager()
                            appDelegate?.startGPSTraking()
                            break
                        default:
                            break
                        }
                    }else{
                        self?.taskButton.setTitle("MAKE ME AVAILABLE", for: .normal)
                        self?.taskButton.backgroundColor = hexStringToUIColor("000000")
                        CurrentUserInfo.dutyStarted = false
                        self?.appDelegate?.stopLocationManager()
                    }
                }
            }
        })
    }
}

extension HomeViewController: UISheetPresentationControllerDelegate {
    func showSubscriptionBottomSheet(){
        guard let subscriptionVC = self.storyboard?.instantiateViewController(withIdentifier: "SubscriptionViewController") as? SubscriptionViewController else {
            return
        }
        
        subscriptionVC.parentViewContoller = self
        self.addDimmingView()
//        subscriptionVC.currentPlan = self.viewModel.user?.lastSubscriptionHistory
//        subscriptionVC.allPlans = subscriptionViewModel.allPlans
        
        // For iOS 15+ sheetPresentationController API
        if #available(iOS 16.0, *) {
            if let sheetPresentationController = subscriptionVC.sheetPresentationController {
                sheetPresentationController.detents = [.custom { context in
                    return 284
                }]
                sheetPresentationController.prefersGrabberVisible = true
                sheetPresentationController.delegate = self // Set the delegate to capture dismissal events
            }
        } else if #available(iOS 15.0, *) {
            if let sheetPresentationController = subscriptionVC.sheetPresentationController {
                // For iOS 15, use a medium detent or adjust based on the available APIs
                sheetPresentationController.detents = [.medium()]
                sheetPresentationController.prefersGrabberVisible = true
                sheetPresentationController.delegate = self
            }
        }
        
        subscriptionVC.modalPresentationStyle = .pageSheet
        self.present(subscriptionVC, animated: true, completion: nil)
        
    }
    
    func addDimmingView() {
        let dimmingView = UIView(frame: self.view.bounds)
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        dimmingView.tag = 999
        dimmingView.alpha = 0
        
        self.view.addSubview(dimmingView)
        
        UIView.animate(withDuration: 0.3) {
            dimmingView.alpha = 1
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissBottomSheet))
        dimmingView.addGestureRecognizer(tapGesture)
    }

    @objc func dismissBottomSheet() {
        if let dimmingView = self.view.viewWithTag(999) {
            UIView.animate(withDuration: 0.3, animations: {
                dimmingView.alpha = 0
            }) { _ in
                dimmingView.removeFromSuperview()
            }
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        if let dimmingView = self.view.viewWithTag(999) {
            UIView.animate(withDuration: 0.3, animations: {
                dimmingView.alpha = 0
            }) { _ in
                dimmingView.removeFromSuperview()
            }
        }
    }
}

extension HomeViewController: SubscriptionManagerDelegate {
    
    func purchaseSuscription() {
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.clear)
        let productIdentifiers = Set(["com.tapitclean.provider.weekly"])
        SubscriptionManager.shared.fetchProducts(productIdentifiers: productIdentifiers)
    }
    
    func restoreSubscription() {
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.clear)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func couponCode() {
        self.dismissBottomSheet()
        coordinator?.goToCouponCodeView()
    }
    
    
    // MARK: - SubscriptionManagerDelegate Methods
    func subscriptionManagerDidFetchProducts(_ manager: SubscriptionManager, products: [SKProduct]) {
        print("Products fetched successfully: \(products)")
        
        DispatchQueue.main.async {
            guard let product = products.first else {
                print("No products were fetched.")
                AlertManager.shared.showAlert(on: self, title: "Error", message: "No subscription available")
                SVProgressHUD.dismiss()
                return
            }
            
            // Initiate the purchase
            print("Initiating purchase for \(product.productIdentifier)")
            SubscriptionManager.shared.purchase(product: product)
        }
    }

    func subscriptionManager(_ manager: SubscriptionManager, didFailWithError error: Error) {
        // This is called when fetching products fails
        // Show an alert or handle the error in the UI
        print("Failed to fetch products: \(error.localizedDescription)")
        DispatchQueue.main.async {
            SVProgressHUD.dismiss()
            AlertManager.shared.showAlert(on: self, title: "Error", message: "Failed to fetch products: \(error.localizedDescription)")
        }
    }
}

// MARK: - SubscriptionManagerPurchaseDelegate
extension HomeViewController: SubscriptionManagerPurchaseDelegate {
    func subscriptionManagerDidRestorePurchaseWithNoRestore() {
        SVProgressHUD.dismiss()
        AlertManager.shared.showAlert(on: self, title: "Tap it Clean it", message: "No product available for restore.")
    }
    
    // 1. Purchase successful
    func subscriptionManagerDidCompletePurchase(
        _ manager: SubscriptionManager,
        productIdentifier: String,
        transactionID: String,
        receipt: String,
        originalTransactionId: String
    ) {
        SVProgressHUD.dismiss()
        if(self.view != nil){
            let subscriptionData: [String: Any] = [
                "planId": productIdentifier,
                "deviceType": "iOS",
                "originalTransactionId": originalTransactionId,
                "transactionId": transactionID,
                "receiptId": receipt,
                "isRestore": false
            ]
            self.dismissBottomSheet()
            self.viewModel.addSubscription(APIsEndPoints.kaddSubscriptionRequest.rawValue , subscriptionData, handler: {(result,statusCode)in
                if statusCode ==  0{
                    DispatchQueue.main.async {
                        CurrentUserInfo.subscriptionEndDate = result.subscriptionEndDate
                        CurrentUserInfo.subscriptionType = result.subscriptionType
                        CurrentUserInfo.totalCredit = result.totalCredit
                    }
                }
            })
//            viewModel.addSubscription(planId: productIdentifier, transactionId: transactionID, receiptId: receipt, originalTransactionId: originalTransactionId){ [weak self] success in
//                if(self?.view != nil){
//                    Loader.hideLoader(view: self!.view)
//                    DispatchQueue.main.async {
//                        if success {
//                            print("API call successful. Returning to previous screen.")
//                            if(self?.lastPlan != nil){
//                                self?.getStarted(UIButton())
//                            }
//                            else{
//                                self?.navigationController?.popViewController(animated: true)
//                            }
//                        } else {
//                            if(self?.viewModel.errorCode == 610){
//                                AlertManager.shared.showAlert(on: self!, title: "MMAI Angel", message: self?.viewModel.errorMessage, okActionHandler: {
//                                    if(self?.lastPlan != nil){
//                                        self?.getStarted(UIButton())
//                                    }
//                                    else{
//                                        self?.navigationController?.popViewController(animated: true)
//                                    }
//                                    
//                                })
//                            }
//                            print("API call failed. Handle error accordingly.")
//                        }
//                    }
//                }
//            }
        }
    }
    
    // 2. Purchase failed
    func subscriptionManagerDidFailPurchase(
        _ manager: SubscriptionManager,
        productIdentifier: String?,
        error: Error
    ) {
        SVProgressHUD.dismiss()
        // You could show an alert to the user or handle the error gracefully
        let productText = productIdentifier ?? "(unknown product)"
        print("Purchase for \(productText) failed with error: \(error.localizedDescription)")
        if let nsError = error as NSError? {
            print("Error code: \(nsError.code)")
            print("Error domain: \(nsError.domain)")
            if(nsError.code != 2){
                AlertManager.shared.showAlert(on: self, title: "Error", message: "Please try again later(\(error.localizedDescription))")
            }
        }
        else{
            AlertManager.shared.showAlert(on: self, title: "Error", message: "Please try again later(\(error.localizedDescription))")
        }
        
        self.dismissBottomSheet()
    }
    
    // 3. Purchase restored
    func subscriptionManagerDidRestorePurchase(
        _ manager: SubscriptionManager,
        productIdentifier: String,
        transactionID: String,
        receipt: String,
        originalTransactionId: String
    ) {
        SVProgressHUD.dismiss()
        if(self.view != nil){
            self.dismissBottomSheet()
            let subscriptionData: [String: Any] = [
                "planId": productIdentifier,
                "deviceType": "iOS",
                "originalTransactionId": originalTransactionId,
                "transactionId": transactionID,
                "receiptId": receipt,
                "isRestore": true
            ]
            self.viewModel.addSubscription(APIsEndPoints.kaddSubscriptionRequest.rawValue , subscriptionData, handler: {(result,statusCode)in
                if statusCode ==  0{
                    DispatchQueue.main.async {
                        CurrentUserInfo.subscriptionEndDate = result.subscriptionEndDate
                        CurrentUserInfo.subscriptionType = result.subscriptionType
                        CurrentUserInfo.totalCredit = result.totalCredit
                    }
                }
            })
//            viewModel.addSubscription(planId: productIdentifier, transactionId: transactionID, receiptId: receipt, originalTransactionId: originalTransactionId, isRestore: true){ [weak self] success in
//                if(self?.view != nil){
//                    Loader.hideLoader(view: self!.view)
//                    DispatchQueue.main.async {
//                        if success {
//                            print("API call successful. Returning to previous screen.")
//                            if(self?.lastPlan != nil){
//                                self?.getStarted(UIButton())
//                            }
//                            else{
//                                self?.navigationController?.popViewController(animated: true)
//                            }
//                        } else {
//                            if(self?.viewModel.errorCode == 611){
//                                AlertManager.shared.showAlert(on: self!, title: "MMAI Angel", message: self?.viewModel.errorMessage, okActionHandler: {
//                                    if(self?.lastPlan != nil){
//                                        self?.getStarted(UIButton())
//                                    }
//                                    else{
//                                        self?.navigationController?.popViewController(animated: true)
//                                    }
//                                })
//                            }
//                            print("API call failed. Handle error accordingly.")
//                        }
//                    }
//                }
//            }
        }
    }
}

