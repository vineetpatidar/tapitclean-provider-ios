
import UIKit
import FirebaseAuth
import Firebase
import SVProgressHUD
import StoreKit

class RequestListViewController: BaseViewController,Storyboarded{
    
    var coordinator: MainCoordinator?
    var refreshControl: UIRefreshControl!
    var isJob : Bool = false
    var isTopUp : Bool = false
    var isPurchase: Bool = false
    var currentRequestId : String = ""
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
        RequestCellApply.registerWithTable(tblView)
        
        tblView.rowHeight = UITableView.automaticDimension
        tblView.estimatedRowHeight = 136
        
        // Set the delegate to receive subscription manager callbacks
        SubscriptionManager.shared.delegate = self
        SubscriptionManager.shared.purchaseDelegate = self
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
        let date = Int(Date().timeIntervalSince1970) - 192*60*60
        let latlng =  APIsEndPoints.kGetAvailableJobs.rawValue +  "?latitude=\(lat ?? "0")&longitude=\(lng ?? "0")&fromDate=\(date)"
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
        
        let cell:UITableViewCell = UITableViewCell()
        
        
        if(isJob){
            let job = viewModel.listArray[indexPath.row]
            
            if((job.jobStatus == 0 || job.jobStatus == 1 || job.jobStatus == 2) && job.isPending == 1){
                let avaCell  = tableView.dequeueReusableCell(withIdentifier: RequestCellApply.reuseIdentifier, for: indexPath) as! RequestCellApply
                avaCell.selectionStyle = .none
                avaCell.commonInit(viewModel.listArray[indexPath.row], self)
                return avaCell
            }
            else {
                let myJobcell = tableView.dequeueReusableCell(withIdentifier: RequestCell.reuseIdentifier, for: indexPath) as! RequestCell
                myJobcell.selectionStyle = .none
                myJobcell.commonInit(viewModel.listArray[indexPath.row])
                return myJobcell
            }
        }
        else{
            let myJobcell = tableView.dequeueReusableCell(withIdentifier: RequestCell.reuseIdentifier, for: indexPath) as! RequestCell
            myJobcell.selectionStyle = .none
            myJobcell.commonInit(viewModel.listArray[indexPath.row])
            return myJobcell
        }
        
        
        return cell
    }
}

extension RequestListViewController: UITableViewDelegate {
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return CGFloat(viewModel.defaultCellHeight)
//    }
    
    func applyButtonTapped(job: RequestListModal){
        //When Job is free for payment
        let endpoint = "\(APIsEndPoints.kapplyRequest.rawValue)\(job.requestId ?? "")"
        var param: [String: Any] = [:]
        param["latitude"] = Double(CurrentUserInfo.latitude ?? "0")
        param["longitude"] = Double(CurrentUserInfo.longitude ?? "0")
        viewModel.applyRequest(endpoint, param) { response, code in
            self.tblView.reloadData()
            //Call Payment now
            if let updatedJob = response{
                if(updatedJob.paymentStatus == "PENDING"){
                    //Call Payment Now
                    self.currentRequestId = job.requestId ?? ""
                    if(CurrentUserInfo.totalCredit >= updatedJob.jobBudgetCredit!){
                        self.showTopupBottomSheetForCredit(credit: updatedJob.jobBudgetCredit!)
                    }
                    else {
                        SVProgressHUD.show()
                        SVProgressHUD.setDefaultMaskType(.clear)
                        let productIdentifiers = Set([updatedJob.iosStoreId!])
                        // Pass the product identifiers to fetchProducts
                        SubscriptionManager.shared.delegate = self
                        SubscriptionManager.shared.fetchProducts(productIdentifiers: productIdentifiers)
                        self.isTopUp = true
                        self.isPurchase = false
                    }
                }
            }
        }
    }
    
    func paidToJob(job: RequestListModal){
        //Payment Block but not paid
        if let paymentTime = job.paymentBlockTime {
            if job.paymentStatus == "PENDING" {
                let paymentBlockTime = Int(paymentTime)
                if paymentBlockTime > Int(Date().timeIntervalSince1970) {
                    self.currentRequestId = job.requestId ?? ""
                    if(CurrentUserInfo.totalCredit >= job.jobBudgetCredit!){
                        self.showTopupBottomSheetForCredit(credit: job.jobBudgetCredit!)
                    }
                    else {
                        //Call Payment Now
                        SVProgressHUD.show()
                        SVProgressHUD.setDefaultMaskType(.clear)
                        let productIdentifiers = Set([job.iosStoreId!])
                        SubscriptionManager.shared.delegate = self
                        SubscriptionManager.shared.fetchProducts(productIdentifiers: productIdentifiers)
                        
                        self.isTopUp = true
                        self.isPurchase = false
                    }
                }
            }
        }
    }
    
    func leaveJobButtonTapped(job: RequestListModal){
        
        if(job.jobStatus == 2 && job.paidPaymentDriverId == CurrentUserInfo.userId){
            //When Job is free for payment
            let endpoint = "\(APIsEndPoints.kleaveRequest.rawValue)\(job.requestId ?? "")"
            let param: [String: Any] = [:]
//            param["latitude"] = Double(CurrentUserInfo.latitude ?? "0")
//            param["longitude"] = Double(CurrentUserInfo.longitude ?? "0")
            viewModel.leaveRequest(endpoint, param) { response, code in
                self.tblView.reloadData()
            }
        }
        
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        let job = viewModel.listArray[indexPath.row]
        if(isJob){
            if((job.jobStatus == 0 || job.jobStatus == 1 || job.jobStatus == 2) && job.isPending == 1){
                if(job.paidPaymentDriverId == CurrentUserInfo.userId ){
                    coordinator?.goToJobView(job.requestId!)
                }
            }
        }
        else{
            coordinator?.goToJobView(job.requestId!)
        }
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
    
    func showTopupBottomSheet(price:String){
        guard let topupVC = self.storyboard?.instantiateViewController(withIdentifier: "TopupViewController") as? TopupViewController else {
            return
        }
        if let job = self.viewModel.listArray.first(where: { $0.requestId == self.currentRequestId }) {
            topupVC.job = job
        }
        
        topupVC.price = price
        topupVC.requestListVC = self
        self.addDimmingView()
//        subscriptionVC.currentPlan = self.viewModel.user?.lastSubscriptionHistory
//        subscriptionVC.allPlans = subscriptionViewModel.allPlans
        
        // For iOS 15+ sheetPresentationController API
        if #available(iOS 16.0, *) {
            if let sheetPresentationController = topupVC.sheetPresentationController {
                sheetPresentationController.detents = [.custom { context in
                    return 224
                }]
                sheetPresentationController.prefersGrabberVisible = true
                sheetPresentationController.delegate = self // Set the delegate to capture dismissal events
            }
        } else if #available(iOS 15.0, *) {
            if let sheetPresentationController = topupVC.sheetPresentationController {
                // For iOS 15, use a medium detent or adjust based on the available APIs
                sheetPresentationController.detents = [.medium()]
                sheetPresentationController.prefersGrabberVisible = true
                sheetPresentationController.delegate = self
            }
        }
        
        topupVC.modalPresentationStyle = .pageSheet
        self.present(topupVC, animated: true, completion: nil)
        
    }
    
    func showTopupBottomSheetForCredit(credit:Int){
        guard let topupVC = self.storyboard?.instantiateViewController(withIdentifier: "TopupViewController") as? TopupViewController else {
            return
        }
        if let job = self.viewModel.listArray.first(where: { $0.requestId == self.currentRequestId }) {
            topupVC.job = job
        }
        
        topupVC.credit = credit
        topupVC.requestListVC = self
        self.addDimmingView()
//        subscriptionVC.currentPlan = self.viewModel.user?.lastSubscriptionHistory
//        subscriptionVC.allPlans = subscriptionViewModel.allPlans
        
        // For iOS 15+ sheetPresentationController API
        if #available(iOS 16.0, *) {
            if let sheetPresentationController = topupVC.sheetPresentationController {
                sheetPresentationController.detents = [.custom { context in
                    return 264
                }]
                sheetPresentationController.prefersGrabberVisible = true
                sheetPresentationController.delegate = self // Set the delegate to capture dismissal events
            }
        } else if #available(iOS 15.0, *) {
            if let sheetPresentationController = topupVC.sheetPresentationController {
                // For iOS 15, use a medium detent or adjust based on the available APIs
                sheetPresentationController.detents = [.medium()]
                sheetPresentationController.prefersGrabberVisible = true
                sheetPresentationController.delegate = self
            }
        }
        
        topupVC.modalPresentationStyle = .pageSheet
        self.present(topupVC, animated: true, completion: nil)
        
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
        isTopUp = false
        isPurchase = false
    }
    
    func purchaseTopup(job:RequestListModal) {
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.clear)
        let productIdentifiers = Set([job.iosStoreId!])
        SubscriptionManager.shared.fetchProducts(productIdentifiers: productIdentifiers)
        self.isTopUp = true
        self.isPurchase = true
    }
    
    func purchaseCredit(job:RequestListModal) {
        var topUpData: [String: Any] = [
            "deviceType": "iOS",
            "isCreditUsed": true
        ]
        topUpData["latitude"] = Double(CurrentUserInfo.latitude ?? "0")
        topUpData["longitude"] = Double(CurrentUserInfo.longitude ?? "0")
        self.dismissBottomSheet()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.saveTopUpDataLocally(topUpData)
        topUpData["requestId"] = self.currentRequestId
        
        let endpoint = APIsEndPoints.kbuyRequest.rawValue
        viewModel.addTopup(endpoint, topUpData) { response, code in
            self.tblView.reloadData()

        }
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
                if(self.isTopUp == false){
                    AlertManager.shared.showAlert(on: self, title: "Error", message: "No subscription available")
                }
                else{
                    AlertManager.shared.showAlert(on: self, title: "Error", message: "No product available")
                }
                
                SVProgressHUD.dismiss()
                return
            }
            
            // Initiate the purchase
            
            if(self.isTopUp == false){
                print("Initiating purchase for \(product.productIdentifier)")
                SubscriptionManager.shared.purchase(product: product)
            }
            else{
                
                if(self.isPurchase){
                    SubscriptionManager.shared.purchase(product: product)
                }
                else{
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .currency
                    formatter.locale = Locale.current
                    
                    
                    let product = products.first!
                    formatter.currencyCode = product.priceLocale.currencyCode // Use product's currency code
                    let price = formatter.string(from: product.price) ?? "\(product.price)"


                    SVProgressHUD.dismiss()
                    self.showTopupBottomSheet(price:price)
                    
                }
            }
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
        if(self.isTopUp){
            if(self.view != nil){
                var topUpData: [String: Any] = [
                    "planId": productIdentifier,
                    "deviceType": "iOS",
                    "originalTransactionId": originalTransactionId,
                    "transactionId": transactionID
                ]
                topUpData["latitude"] = Double(CurrentUserInfo.latitude ?? "0")
                topUpData["longitude"] = Double(CurrentUserInfo.longitude ?? "0")
                self.dismissBottomSheet()
                
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                appDelegate?.saveTopUpDataLocally(topUpData)
                topUpData["requestId"] = self.currentRequestId
                
                let endpoint = APIsEndPoints.kbuyRequest.rawValue
                viewModel.addTopup(endpoint, topUpData) { response, code in
                    self.tblView.reloadData()
                    //Call Payment now
//                    if let updatedJob = response{
//                        if(updatedJob.paymentStatus == "PENDING"){
//                            //Call Payment Now
//                            SVProgressHUD.show()
//                            SVProgressHUD.setDefaultMaskType(.clear)
//                            let productIdentifiers = Set([updatedJob.iosStoreId!])
//                            self.currentRequestId = job.requestId ?? ""
//                            // Pass the product identifiers to fetchProducts
//                            SubscriptionManager.shared.delegate = self
//                            SubscriptionManager.shared.fetchProducts(productIdentifiers: productIdentifiers)
//                            self.isTopUp = true
//                            self.isPurchase = false
//                        }
//                    }
                }
                
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
        else{
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
                            CurrentUserInfo.subscriptionType = result.subscriptionType
                            CurrentUserInfo.totalCredit = result.totalCredit
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
                        CurrentUserInfo.subscriptionType = result.subscriptionType
                        CurrentUserInfo.totalCredit = result.totalCredit
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
