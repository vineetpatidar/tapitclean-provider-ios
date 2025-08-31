//
//  SubscriptionViewController.swift
//  TICProvider
//
//  Created by vineet patidar on 07/06/25.
//

import UIKit

class TopupViewController: UIViewController {

    @IBOutlet weak var btnCouponCode: UIButton!
    @IBOutlet weak var btnPurchaseSubscription: UIButton!
    @IBOutlet weak var jobLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    var requestListVC:RequestListViewController?
    var job:RequestListModal?
    var price:String = ""
    var credit:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.jobLabel.text = "Request ID: \(self.job?.reqDispId ?? "")"
        if(price == ""){
            self.messageLabel.text = "To view and access this job you need to pay \(credit) credits."
            self.btnPurchaseSubscription.setTitle("PAY \(credit) credits", for: .normal)
        }
        else{
            self.messageLabel.text = "To view and access this job you need to pay \(price)."
            self.btnPurchaseSubscription.setTitle("PAY \(price)", for: .normal)
        }
        
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func btnPurchaseSubscription_Clicked(_ sender: Any) {
        if(price == ""){
            self.requestListVC?.purchaseCredit(job: job!)
        }
        else{
            self.requestListVC?.purchaseTopup(job: job!)
        }
        
    }
    
    @IBAction func btnCouponCode_Clicked(_ sender: Any) {
        self.requestListVC?.couponCode()
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
