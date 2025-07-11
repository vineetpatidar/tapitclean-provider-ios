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
                "couponCode": txtReedemCode.text ?? "",
                "deviceType": "iOS"
            ]
            self.viewModel.reedemCouponCode(APIsEndPoints.kapplyCouponCodeRequest.rawValue , reedemData, handler: {(result,statusCode)in
                if statusCode ==  0{
                    DispatchQueue.main.async {
                        CurrentUserInfo.subscriptionEndDate = result.subscriptionEndDate
                        var message: String = ""
                        if let msg = result.message{
                            message = msg
                        }
                        self.showSccessBottomSheet(infoMsg: message)
//                        AlertManager.shared.showAlert(on: self, title: "Hooray! Your coupon has been successfully redeemed.", message: message, okActionHandler: {
//                            self.navigationController?.popViewController(animated: true)
//                        })
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
            self.lblError.text = "Please enter the coupon code to reedeem"
            self.lblError.isHidden = false
//            AlertManager.shared.showAlert(on: self, title: "error", message: "Please enter the coupon code to reedeem")
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

extension ReedemCouponViewController: UISheetPresentationControllerDelegate {
    func showSccessBottomSheet(infoMsg: String){
        guard let successVC = self.storyboard?.instantiateViewController(withIdentifier: "RCSuccessViewController") as? RCSuccessViewController else {
            return
        }
        
        successVC.parentViewContoller = self
        successVC.infoMsg = infoMsg
        self.addDimmingView()
        
        // For iOS 15+ sheetPresentationController API
        if #available(iOS 16.0, *) {
            if let sheetPresentationController = successVC.sheetPresentationController {
                sheetPresentationController.detents = [.custom { context in
                    return 332
                }]
                sheetPresentationController.prefersGrabberVisible = true
                sheetPresentationController.delegate = self // Set the delegate to capture dismissal events
            }
        } else if #available(iOS 15.0, *) {
            if let sheetPresentationController = successVC.sheetPresentationController {
                // For iOS 15, use a medium detent or adjust based on the available APIs
                sheetPresentationController.detents = [.medium()]
                sheetPresentationController.prefersGrabberVisible = true
                sheetPresentationController.delegate = self
            }
        }
        
        successVC.modalPresentationStyle = .pageSheet
        self.present(successVC, animated: true, completion: nil)
        
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
        self.navigationController?.popViewController(animated: true)
    }
    
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        if let dimmingView = self.view.viewWithTag(999) {
            UIView.animate(withDuration: 0.3, animations: {
                dimmingView.alpha = 0
            }) { _ in
                dimmingView.removeFromSuperview()
            }
        }
        
        self.navigationController?.popViewController(animated: true)
    }
}
