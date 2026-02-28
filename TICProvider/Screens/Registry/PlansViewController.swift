//
//  PlansViewController.swift
//  TICProvider
//
//  Created by vineet patidar on 07/02/26.
//

import UIKit
import SVProgressHUD
import StoreKit

class PlansViewController: BaseViewController,Storyboarded, SubscriptionManagerDelegate {
    
    var coordinator: MainCoordinator?
    var appDelegate : AppDelegate?
    var isCredit:Bool = false
    
    @IBOutlet weak var subscriptionView: UIView!
    @IBOutlet weak var btnBuySubscription: UIButton!
    @IBOutlet weak var btnCancelSubscription: UIButton!
    @IBOutlet weak var btnAddCredits: UIButton!
    
    @IBOutlet weak var lblSubscriptionEndDate: UILabel!
    @IBOutlet weak var lblBilled: UILabel!
    @IBOutlet weak var lblPlanName: UILabel!
    @IBOutlet weak var lblCredit: UILabel!
    
    var packages:[PackageModel] = []
    
    var viewModel : HomeViewModal = {
        let viewModel = HomeViewModal()
        return viewModel
    }()
    
    @IBAction func btnBuySubscription_Clicked(_ sender: Any) {
//        coordinator?.goToInAppPurchase("subscription")
        let productIdentifiers: Set<String> = Set(
            packages
                .filter { $0.type == "subscription" }
                .compactMap { $0.id }   // safer than map
        )
        
        guard !productIdentifiers.isEmpty else {
            print("No credit products found")
            return
        }
        
        // UI updates must be on main thread
        DispatchQueue.main.async {
            SVProgressHUD.setDefaultMaskType(.clear)
            SVProgressHUD.show()
            // Fetch IAP products
            SubscriptionManager.shared.fetchProducts(productIdentifiers: productIdentifiers)
            self.isCredit = false
        }
        
    }
    @IBAction func btnCancelSubscription_Clicked(_ sender: Any) {
        // Open the App Store subscription management page
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            print("Failed to open subscription management URL.")
        }
    }
    
    @IBAction func btnAddCredits_Clicked(_ sender: Any) {
//        coordinator?.goToInAppPurchase("credit")
        // Extract product IDs safely
        let productIdentifiers: Set<String> = Set(
            packages
                .filter { $0.type == "credit" }
                .compactMap { $0.id }   // safer than map
        )
        
        guard !productIdentifiers.isEmpty else {
            print("No credit products found")
            return
        }
        
        // UI updates must be on main thread
        DispatchQueue.main.async {
            SVProgressHUD.setDefaultMaskType(.clear)
            SVProgressHUD.show()
            // Fetch IAP products
            SubscriptionManager.shared.fetchProducts(productIdentifiers: productIdentifiers)
            self.isCredit = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        if((self.navigationController?.viewControllers.count)! >= 2){
            setNavWithOutView(.back)
        }
        else{
            setNavWithOutView(.menu)
        }
        
        btnAddCredits.layer.borderColor = UIColor(hexString: "#D1E8C3").cgColor
        btnAddCredits.layer.borderWidth = 1.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SubscriptionManager.shared.delegate = self
        self.getPackageInfo()
    }
    
    @IBAction func btnCouponCode_Clicked(_ sender: Any) {
        coordinator?.goToCouponCodeView()
    }
        
    private func getPackageInfo(showLoader: Bool = true) {
        self.subscriptionView.isHidden = true
        self.lblCredit.text = "--"
        viewModel.getPackages(APIsEndPoints.kpackagesRequest.rawValue) { [weak self] (result, statusCode) in
            guard let self = self else { return }
            self.subscriptionView.isHidden = false
            DispatchQueue.main.async {
                if statusCode == 0 {
                    if let packages = result.packages {
                        self.packages = packages
                    }

                    if result.driver != nil {
                        CurrentUserInfo.subscriptionEndDate = result.driver?.subscriptionEndDate
                        CurrentUserInfo.subscriptionType = result.driver?.subscriptionType
                        CurrentUserInfo.totalCredit = result.driver?.totalCredit
                        self.setupUI()
                    } else {
                        AlertManager.shared.showAlert(
                            on: self, title: "Oops",
                            message: "Something went wrong"
                        )
                    }

                } else {
                    AlertManager.shared.showAlert(
                        on: self,
                        title: "Error",
                        message: "Failed to fetch package info. Please try again."
                    )
                }
            }
        }
    }
    
    func setupUI() {
        subscriptionView.isHidden = false
        self.lblCredit.text = String(CurrentUserInfo.totalCredit)
        let currentTime = Int64(Date().timeIntervalSince1970)
        let expired = CurrentUserInfo.subscriptionEndDate <= currentTime
        self.lblPlanName.text = CurrentUserInfo.subscriptionType
            if expired == true {
//                self.lblPlanName.text = "\(self.lblPlanName.text ?? "") (Expired)"
                btnCancelSubscription.isHidden = true
            }
            
        
        if(CurrentUserInfo.subscriptionType.lowercased().starts(with: "trial") || CurrentUserInfo.subscriptionType.lowercased().starts(with: "coupon")){
            lblBilled.isHidden = true
        }
        else{
            lblBilled.isHidden = false
            btnCancelSubscription.isHidden = false
        }

        self.lblSubscriptionEndDate.attributedText = getFormattedEndDateAttributedString(endAt: CurrentUserInfo.subscriptionEndDate, expired: expired)
    }
    
    func getFormattedEndDateAttributedString(endAt: Int, expired: Bool) -> NSAttributedString {

        // Convert Unix timestamp → Date
        let date = Date(timeIntervalSince1970: TimeInterval(endAt))
        
        // Output date formatter
        let outputDateFormatter = DateFormatter()
        outputDateFormatter.dateFormat = "MMM d, yyyy"
        
        let formattedDate = outputDateFormatter.string(from: date)

        // Attributes
        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "HelveticaNeue-Bold", size: 14) ?? UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.white
        ]

        let regularAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "HelveticaNeue", size: 14) ?? UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.white
        ]

        // Text
        var fullString = "Subscription End Date: \(formattedDate)"
        if expired {
            fullString += " (Expired)"
        }

        let attributedString = NSMutableAttributedString(string: fullString, attributes: regularAttributes)

        // Bold only the date
        if let range = fullString.range(of: formattedDate) {
            attributedString.addAttributes(boldAttributes, range: NSRange(range, in: fullString))
        }

        return attributedString
    }
    
    // MARK: - SubscriptionManagerDelegate Methods
    func subscriptionManagerDidFetchProducts(_ manager: SubscriptionManager, products: [SKProduct]) {
        print("Products fetched successfully: \(products)")
        
        DispatchQueue.main.async {
            SVProgressHUD.dismiss()
            
            // Extract the product identifiers from the fetched products
            let productIDs = products.map { $0.productIdentifier }
            
            // Filter the suggestedPlans to include only those with matching product IDs
            let filteredPlans = self.packages.filter { productIDs.contains($0.id) }
            
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = Locale.current
            var plans: [PackageModel] = []
            products.forEach { product in
                if var plan = filteredPlans.first(where: { $0.id == product.productIdentifier }) {
                    formatter.currencyCode = product.priceLocale.currencyCode // Use product's currency code
                    plan.appstorePrice = formatter.string(from: product.price) ?? "\(product.price)"
                    plans.append(plan)
                }
            }
            

            
            // Check if we have any filtered plans
            if plans.isEmpty && !self.isCredit {
                AlertManager.shared.showAlert(on: self, title: "Error", message: "No subscription available")
                return
            }
            // Check if we have any filtered plans
            else if plans.isEmpty && self.isCredit {
                AlertManager.shared.showAlert(on: self, title: "Error", message: "No Job Credits plans available")
                return
            }
            

            if(self.isCredit){
                plans.sort(by: { $0.value < $1.value })
                self.coordinator?.goToInAppPurchase("credit", packages:plans)
            }
            else{
                plans.sort(by: { $0.value < $1.value })
                self.coordinator?.goToInAppPurchase("subscription", packages:plans)
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
