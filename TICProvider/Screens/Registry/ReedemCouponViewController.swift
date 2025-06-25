//
//  ReedemCouponViewController.swift
//  TICProvider
//
//  Created by vineet patidar on 18/06/25.
//

import UIKit

class ReedemCouponViewController: BaseViewController,Storyboarded,UITextFieldDelegate {
    
    var parentHomeView: HomeViewController?
    
    @IBOutlet weak var lblError: UILabel!
    @IBOutlet weak var btnReedemCode: UIButton!
    @IBOutlet weak var txtReedemCode: UITextField!
    var viewModel : CouponCodeViewModal = {
        let viewModel = CouponCodeViewModal()
        return viewModel }()

    override func viewDidLoad() {
        super.viewDidLoad()
        if(self.navigationController?.viewControllers.count ?? 0 > 1){
            self.setNavWithOutView(ButtonType.back)
        }
        setupUI()
    }
    
    func setupUI() {
        lblError.isHidden = true
        lblError.text = ""
        // Add padding
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 40))
        txtReedemCode.leftView = leftPaddingView
        txtReedemCode.leftViewMode = .always
        txtReedemCode.delegate = self
    }
    

    
    @IBAction func btnReedemCode_Clicked(_ sender: Any) {
        if isValidCouponCode(txtReedemCode.text ?? "") {
            txtReedemCode.resignFirstResponder()
            let reedemData: [String: Any] = [
                "couponCode": txtReedemCode.text ?? ""
            ]
            self.viewModel.reedemCouponCode(APIsEndPoints.kapplyCouponCodeRequest.rawValue , reedemData, handler: {(result,statusCode)in
                if statusCode ==  0{
                    DispatchQueue.main.async {
                        CurrentUserInfo.subscriptionEndDate = result.subscriptionEndDate
                        AlertManager.shared.showAlert(on: self, title: "Hooray! Your coupon has been successfully redeemed.", message: self.viewModel.successMessage ?? "", okActionHandler: {
                            self.navigationController?.popViewController(animated: true)
                        })
                        print("API call successful. Returning to previous screen.")
                    }
                }
                else{
                    DispatchQueue.main.async {
                        self.lblError.text = self.viewModel.errorMessage
                        self.lblError.isHidden = false
                        print("API call failed. Handle error accordingly.")
                    }
                }
            })

        } else {
            AlertManager.shared.showAlert(on: self, title: "error", message: "Please enter the coupon code to reedeem")
        }
    }
    
    // UITextFieldDelegate method
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        lblError.isHidden = true
        lblError.text = ""
        return true // Allow the text to be changed
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        lblError.isHidden = true
        lblError.text = ""
        return true // Return true to allow clearing the text
    }
    
    func isValidCouponCode(_ code: String) -> Bool {
        return !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

}
