//
//  InAppPurchaseViewController.swift
//  TICProvider
//
//  Created by vineet patidar on 08/02/26.
//

import UIKit
import SVProgressHUD
import StoreKit

class InAppPurchaseViewController: BaseViewController,Storyboarded {
    var coordinator: MainCoordinator?
    var appDelegate : AppDelegate?
    var type : String = "subscription"
    var data : [PackageModel] = []
    var isSubscription : Bool = false
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var tblSubscription: UITableView!
    @IBOutlet weak var btnRestore: UIButton!
    
    var viewModel : HomeViewModal = {
        let viewModel = HomeViewModal()
        return viewModel
    }()
    
    var reqViewModel : RequestListViewModal = {
        let model = RequestListViewModal()
        return model
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        if((self.navigationController?.viewControllers.count)! >= 2){
            setNavWithOutView(.back)
        }
        else{
            setNavWithOutView(.menu)
        }
        
        if(self.type == "credit"){
            lblTitle.text = "Credits"
        }
        else {
            lblTitle.text = "Subscriptions"
            btnRestore.isHidden = false
            isSubscription = true
        }
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SubscriptionManager.shared.delegate = self
        SubscriptionManager.shared.purchaseDelegate = self
//        self.getPackageInfo()
    }
    
    func setupTableView() {
        tblSubscription.backgroundColor = UIColor.clear
        tblSubscription.separatorStyle = .none
        tblSubscription.register(UINib(nibName: SubscriptionsCell.identifier, bundle: nil), forCellReuseIdentifier: SubscriptionsCell.identifier)
    }
    
    private func getPackageInfo(showLoader:Bool = true) {
        self.viewModel.getPackages(APIsEndPoints.kpackagesRequest.rawValue , handler: {[weak self](result,statusCode)in
            if statusCode ==  200{
                self?.data = (result.packages?.filter({$0.type == self?.type}))!
                DispatchQueue.main.async {
                    self?.setupUI()
                }
            }
        })
    }
    
    func setupUI() {}
    
    @IBAction func btnRestore_Clicked(_ sender: Any) {
        print("Restore button clicked.")
        
        SVProgressHUD.show()
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    @objc func addSubscribe(_ sender: UIButton) {
//        if(self.type == "credit"){
            SVProgressHUD.show()
            SVProgressHUD.setDefaultMaskType(.clear)
            let item = self.data[sender.tag]
            print("Selected item: \(item)")
            let productIdentifiers = Set([item.id])
            SubscriptionManager.shared.fetchProducts(productIdentifiers: productIdentifiers)
//        }
//        else{
//            
//        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension InAppPurchaseViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - TableView DataSource and Delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SubscriptionsCell.identifier, for: indexPath) as! SubscriptionsCell
        let item = data[indexPath.row]
        cell.btnPaid.tag = indexPath.row
        cell.btnPaid.addTarget(self, action: #selector(addSubscribe(_:)), for: .touchUpInside)
        cell.configure(with: item, isSubscription: isSubscription)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Handle row selection
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension InAppPurchaseViewController: SubscriptionManagerDelegate {
    // MARK: - SubscriptionManagerDelegate Methods
    func subscriptionManagerDidFetchProducts(_ manager: SubscriptionManager, products: [SKProduct]) {
        print("Products fetched successfully: \(products)")
        
        DispatchQueue.main.async {
            guard let product = products.first else {
                print("No products were fetched.")
                if(self.type == "subscription"){
                    AlertManager.shared.showAlert(on: self, title: "Error", message: "No subscription available")
                }
                else{
                    AlertManager.shared.showAlert(on: self, title: "Error", message: "No product available")
                }
                
                SVProgressHUD.dismiss()
                return
            }
            
            // Initiate the purchase
            
//            if(self.type == "subscription"){
//                print("Initiating purchase for \(product.productIdentifier)")
//                SubscriptionManager.shared.purchase(product: product)
//            }
//            else{
                SubscriptionManager.shared.purchase(product: product)
//            }
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
extension InAppPurchaseViewController: SubscriptionManagerPurchaseDelegate {
    // 1. Purchase successful
    func subscriptionManagerDidCompletePurchase(
        _ manager: SubscriptionManager,
        productIdentifier: String,
        transactionID: String,
        receipt: String,
        originalTransactionId: String
    ) {
        SVProgressHUD.dismiss()
        if(self.type == "credit"){
            if(self.view != nil){
                var topUpData: [String: Any] = [
                    "planId": productIdentifier,
                    "deviceType": "iOS",
                    "originalTransactionId": originalTransactionId,
                    "transactionId": transactionID
                ]
                topUpData["latitude"] = Double(CurrentUserInfo.latitude ?? "0")
                topUpData["longitude"] = Double(CurrentUserInfo.longitude ?? "0")
                
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                appDelegate?.saveTopUpDataLocally(topUpData)
                
                let endpoint = APIsEndPoints.kbuyRequest.rawValue
                reqViewModel.addTopup(endpoint, topUpData) { result, code in
                    print("\(result, default: "")")
                    print(code)
                    if code ==  0{
                        DispatchQueue.main.async {
                            CurrentUserInfo.subscriptionEndDate = result?.driver?.subscriptionEndDate
                            CurrentUserInfo.subscriptionType = result?.driver?.subscriptionType
                            CurrentUserInfo.totalCredit = result?.driver?.totalCredit
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                }
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
                self.viewModel.addSubscription(APIsEndPoints.kaddSubscriptionRequest.rawValue , subscriptionData, handler: {(result,statusCode)in
                    if statusCode ==  0{
                        DispatchQueue.main.async {
                            CurrentUserInfo.subscriptionEndDate = result.subscriptionEndDate
                            CurrentUserInfo.subscriptionType = result.subscriptionType
                            CurrentUserInfo.totalCredit = result.totalCredit
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                })
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
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            })
        }
    }
    
    func subscriptionManagerDidRestorePurchaseWithNoRestore(){
        SVProgressHUD.dismiss()
        AlertManager.shared.showAlert(on: self, title: "Tap it Clean it", message: "No product available for restore.")
    }
}
