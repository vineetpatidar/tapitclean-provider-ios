//
//  SubscriptionViewController.swift
//  TICProvider
//
//  Created by vineet patidar on 07/06/25.
//

import UIKit

class SubscriptionViewController: UIViewController {

    @IBOutlet weak var btnRestoreSubscription: UIButton!
    @IBOutlet weak var btnCouponCode: UIButton!
    @IBOutlet weak var btnPurchaseSubscription: UIButton!
    
    var parentViewContoller:HomeViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func btnPurchaseSubscription_Clicked(_ sender: Any) {
        self.parentViewContoller?.purchaseSuscription()
    }
    
    @IBAction func btnCouponCode_Clicked(_ sender: Any) {
        self.parentViewContoller?.couponCode()
    }
    @IBAction func btnRestoreSubscription_Clicked(_ sender: Any) {
        self.parentViewContoller?.restoreSubscription()
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
