
import UIKit
import FirebaseAuth
import Firebase
import SVProgressHUD
import StoreKit

class RequestListViewController: BaseViewController,Storyboarded{
    
    var coordinator: MainCoordinator?
    var refreshControl: UIRefreshControl!
    var isJob : Bool = false
    @IBOutlet weak var headingTitle: UILabel!
    
    @IBOutlet weak var tblContainerView: UIView!
    @IBOutlet weak var subscriptionView: UIView!
    @IBOutlet weak var tblView: UITableView!
   
    var viewModel : RequestListViewModal = {
        let model = RequestListViewModal()
        return model
    }()
    
    var homeViewModel : HomeViewModal = {
        let viewModel = HomeViewModal()
        return viewModel }()
    
    deinit {
        SKPaymentQueue.default().remove(SubscriptionManager.shared)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tblView.addSubview(refreshControl)

        coordinator = MainCoordinator(navigationController: self.navigationController!)
        self.headingTitle.text = self.isJob ? "Available Jobs" : "MY JOBS"
        self.setNavWithOutView(ButtonType.menu)
        RequestCell.registerWithTable(tblView)
        tblView.rowHeight = UITableView.automaticDimension
        tblView.estimatedRowHeight = 136
        
        // Set the delegate to receive subscription manager callbacks
        SubscriptionManager.shared.delegate = self
        SubscriptionManager.shared.purchaseDelegate = self
        // Add the payment queue observer to handle purchase updates
        SKPaymentQueue.default().add(SubscriptionManager.shared)
        subscriptionView.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.getAllRequestList()
    }
    
    @objc func refresh(_ sender: Any) {
        refreshControl.endRefreshing()
        self.getAllRequestList()
    }
    

    
    func getAllRequestList(_ loading : Bool = true){
        if(self.isJob){
            let currentDate = Date()
            let timestampInSeconds = Int(currentDate.timeIntervalSince1970)
            
            if (CurrentUserInfo.subscriptionEndDate < timestampInSeconds){
                subscriptionView.isHidden = false
                return
            }
            else{
                subscriptionView.isHidden = true
            }
        }
        
        
        let lat =  CurrentUserInfo.latitude
        let lng = CurrentUserInfo.longitude
        
        let latlng =  APIsEndPoints.kGetAvailableJoobs.rawValue +  "?latitude=\(lat ?? "0")&longitude=\(lng ?? "0")"
        let endpoint = self.isJob ? latlng : APIsEndPoints.requestList.rawValue
        viewModel.sendRequest(endpoint) { response, code in
            
            if(response.count > 0){
                self.viewModel.listArray  = response
                self.tblView.reloadData()
            }else{
                self.tblView.isHidden = true
                AppUtility.addPLaceHolderLabel("No jobs found", self.view)
            }
        }
    }
    
    @IBAction func btnSubscribeNow_Clicked(_ sender: Any) {
        showSubscriptionBottomSheet()
    }
}
// UITableViewDataSource
extension RequestListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.listArray.count 
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell  = tableView.dequeueReusableCell(withIdentifier: RequestCell.reuseIdentifier, for: indexPath) as! RequestCell
        cell.selectionStyle = .none
        cell.commonInit(viewModel.listArray[indexPath.row])
        
        return cell
    }
}

extension RequestListViewController: UITableViewDelegate {
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return CGFloat(viewModel.defaultCellHeight)
//    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        
        let dictResponse = self.viewModel.listArray[indexPath.row]
            coordinator?.goToJobView(dictResponse.requestId!)

    }
}

extension RequestListViewController: UISheetPresentationControllerDelegate {
    func showSubscriptionBottomSheet(){
        guard let subscriptionVC = self.storyboard?.instantiateViewController(withIdentifier: "SubscriptionViewController") as? SubscriptionViewController else {
            return
        }
        
        subscriptionVC.requestListVC = self
        self.addDimmingView()
//        subscriptionVC.currentPlan = self.viewModel.user?.lastSubscriptionHistory
//        subscriptionVC.allPlans = subscriptionViewModel.allPlans
        
        // For iOS 15+ sheetPresentationController API
        if #available(iOS 16.0, *) {
            if let sheetPresentationController = subscriptionVC.sheetPresentationController {
                sheetPresentationController.detents = [.custom { context in
                    return 324
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

extension RequestListViewController: SubscriptionManagerDelegate {
    
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
extension RequestListViewController: SubscriptionManagerPurchaseDelegate {
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
            self.homeViewModel.addSubscription(APIsEndPoints.kaddSubscriptionRequest.rawValue , subscriptionData, handler: {(result,statusCode)in
                if statusCode ==  0{
                    DispatchQueue.main.async {
                        CurrentUserInfo.subscriptionEndDate = result.subscriptionEndDate
                        self.getAllRequestList()
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
            self.homeViewModel.addSubscription(APIsEndPoints.kaddSubscriptionRequest.rawValue , subscriptionData, handler: {(result,statusCode)in
                if statusCode ==  0{
                    DispatchQueue.main.async {
                        CurrentUserInfo.subscriptionEndDate = result.subscriptionEndDate
                        self.getAllRequestList()
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
