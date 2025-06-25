//
//  RCSuccessViewController.swift
//  TICProvider
//
//  Created by vineet patidar on 25/06/25.
//

import UIKit

class RCSuccessViewController: UIViewController {
    
    var parentViewContoller:ReedemCouponViewController?
    @IBOutlet weak var lblMsg: UILabel!
    var infoMsg:String?

    override func viewDidLoad() {
        super.viewDidLoad()
        lblMsg.text = infoMsg
        // Do any additional setup after loading the view.
    }
    
    @IBAction func btnThankYou_Clicked(_ sender: Any) {
        parentViewContoller?.dismissBottomSheet()
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
