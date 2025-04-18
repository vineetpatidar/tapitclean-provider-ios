//
//  HandoverAddressViewController.swift
//  KWDriver
//
//  Created by Lavanya Patidar on 05/05/24.
//

import UIKit
import FirebaseAuth
import Firebase
import CoreLocation
import SVProgressHUD

protocol HandoverAddressChangeDelegate: AnyObject {
    func handoverAddressChangeAction(infoArray: [AddressTypeModel],_ lat: String,_ lng : String)
}


class HandoverAddressViewController: BaseViewController,Storyboarded {
    
    var coordinator: MainCoordinator?
    
    @IBOutlet weak var tblView: UITableView!
    @IBOutlet weak var landmarkTextView: UITextView!
    
    @IBOutlet weak var mainBG: UIView!
    
    var addressField1: CustomTextField!
    var cityField: CustomTextField!
    var stateField: CustomTextField!
    var landMarkField: CustomTextField!
    var postalCodeField: CustomTextField!
    var locationManager:CLLocationManager? = nil
    
    
    var addressDelegate : HandoverAddressChangeDelegate?
    @IBOutlet weak var viewBG: UIView!
    
    var viewModel : AddressViewModel = {
        let model = AddressViewModel()
        return model
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNavWithOutView(.back)
        viewModel.infoArray = (self.viewModel.prepareInfo(dictInfo: viewModel.dictInfo))
        
        viewBG.layer.borderWidth = 1
        viewBG.layer.borderColor = UIColor.black.cgColor
        viewBG.layer.cornerRadius = 8
        
        landmarkTextView.contentInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        // we are setting defaut value here
        self.viewModel.infoArray[4].value = "United States"
        setupUI()
        
    }
    
    // SsetupUI
    fileprivate func setupUI(){
        SigninCell.registerWithTable(tblView)
        landmarkTextView.text = self.viewModel.infoArray[6].value != "" ? self.viewModel.infoArray[6].value : "Type..."
        landmarkTextView.textColor = .lightGray
    }
    
    
    @IBAction func useDefaultAddAction(_ sender: Any) {
        if(locationManager == nil){
            locationManager = CLLocationManager()
        }
        locationManager!.delegate = nil
        locationManager!.desiredAccuracy = kCLLocationAccuracyBest
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .notDetermined:
            locationManager!.delegate = self
            locationManager!.requestWhenInUseAuthorization()
        case .restricted, .denied:
            let alert = UIAlertController(title: "Allow Location Access", message: "Driver App needs access to your location. Turn on Location Services in your device settings.", preferredStyle: UIAlertController.Style.alert)
            
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
            break
            
        case .authorizedWhenInUse,.authorizedAlways:
            SVProgressHUD.show()
            locationManager!.delegate = self
            locationManager!.startUpdatingLocation()
            break
        default:
            break
        }
    }
    
    @IBAction func saveButtonAction(_ sender: Any) {
        addressField1.resignFirstResponder()
        cityField.resignFirstResponder()
        stateField.resignFirstResponder()
        landmarkTextView.resignFirstResponder()
        postalCodeField.resignFirstResponder()
        viewModel.validateFields(dataStore: viewModel.infoArray) { [self] (dict, msg, isSucess) in
            if isSucess {
                
                if(self.addressField1.text == ""){
                    DispatchQueue.main.async {
                        Alert(title: "", message: "Please enter address", vc: self)
                    }
                }else{
                    
                    viewModel.infoArray[5].value = ""
                    //                let values = viewModel.infoArray.map {$0.value}
                    var values = [String]()
                    for i in 0..<5 {
                        var stringValue = viewModel.infoArray[i].value
                        if(stringValue != nil){
                            stringValue = stringValue.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ",")))
                        }
                        if !stringValue.isEmpty {
                            values.append(stringValue)
                        }
                    }
                    let tempAddress  = values.joined(separator: (", "))
                    viewModel.infoArray[5].value = tempAddress
                    self.getLatLongfromAddress(tempAddress)
                }
                
            }
            else {
                DispatchQueue.main.async {
                    Alert(title: "", message: msg, vc: self)
                }
            }
        }
    }
    
    
    func getLatLongfromAddress(_ address : String){
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(address) { (placemarks, error) in
            guard
                let placemarks = placemarks,
                let location = placemarks.first?.location
            else {
                Alert(title: "", message: "You have entered wrong address", vc: self)
                return
            }
            
            
            self.addressDelegate?.handoverAddressChangeAction(infoArray: self.viewModel.infoArray,"\(location.coordinate.latitude)","\(location.coordinate.longitude)")
            self.navigationController?.popViewController(animated: false)
            
        }
    }
}

// UITableViewDataSource
extension HandoverAddressViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell  = tableView.dequeueReusableCell(withIdentifier: SigninCell.reuseIdentifier, for: indexPath) as! SigninCell
        cell.selectionStyle = .none
        
        switch indexPath.row {
            
        case 0:
            addressField1 = cell.textFiled
            addressField1.delegate = self
            addressField1.returnKeyType = .next
            addressField1.text = viewModel.infoArray[0].value
            addressField1.keyboardType = .default
            addressField1.isUserInteractionEnabled = true
            
        case 1:
            cityField = cell.textFiled
            cityField.delegate = self
            cityField.returnKeyType = .next
            cityField.keyboardType = .default
            cityField.text = viewModel.infoArray[1].value
            
        case 2:
            stateField = cell.textFiled
            stateField.delegate = self
            stateField.returnKeyType = .next
            stateField.keyboardType = .default
            stateField.text = viewModel.infoArray[2].value
            
        case 3:
            postalCodeField = cell.textFiled
            postalCodeField.delegate = self
            postalCodeField.returnKeyType = .next
            postalCodeField.text = viewModel.infoArray[3].value
            postalCodeField.keyboardType = .numberPad
        default:
            break
        }
        
        cell.commiAddressInit(viewModel.infoArray[indexPath.row])
        
        return cell
    }
}

extension HandoverAddressViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(viewModel.defaultCellHeight)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        
    }
}

extension HandoverAddressViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        if textField == addressField1{
            cityField.becomeFirstResponder()
        }
        else if textField == cityField{
            stateField.becomeFirstResponder()
        }
        else   if textField == stateField{
            stateField.resignFirstResponder()
        }
        else   if textField == stateField{
            postalCodeField.resignFirstResponder()
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    {
        let point = tblView.convert(textField.bounds.origin, from: textField)
        let index = tblView.indexPathForRow(at: point)
        let str = (textField.text as NSString?)?.replacingCharacters(in: range, with: string)
        viewModel.infoArray[index?.row ?? 0].value = str ?? ""
        
        return true
    }
}

extension HandoverAddressViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.text = ""
        textView.textColor = .white
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Type..."
            textView.textColor = UIColor.lightGray
        }
        else{
            textView.textColor = UIColor.white
        }
        self.viewModel.infoArray[6].value = textView.text
    }
}

extension HandoverAddressViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        let userLocation: CLLocation = locations.last!
        print("location: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
        if(locationManager != nil){
            locationManager!.stopUpdatingLocation()
            locationManager = nil
        }
        
        self.viewModel.getAddressFromLatLon(latitude: "\(userLocation.coordinate.latitude)", withLongitude: "\(userLocation.coordinate.longitude)",handler: {address in
            SVProgressHUD.dismiss()
            self.tblView.reloadData()
        })
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            break
        case .restricted, .denied:
            SVProgressHUD.dismiss()
            if(locationManager != nil){
                locationManager!.stopUpdatingLocation()
                locationManager = nil
            }
            break
            
        case .authorizedWhenInUse,.authorizedAlways:
            manager.startUpdatingLocation()
            break
            
        default:
            SVProgressHUD.dismiss()
            break
        }
    }
    
    
    
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        SVProgressHUD.dismiss()
        if(locationManager != nil){
            locationManager!.stopUpdatingLocation()
            locationManager = nil
        }
    }
}
