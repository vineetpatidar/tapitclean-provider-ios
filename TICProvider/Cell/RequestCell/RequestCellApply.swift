//
//  RequestCellApply.swift
//  TICProvider
//
//  Created by vineet patidar on 28/07/25.
//

import UIKit

class RequestCellApply: ReusableTableViewCell {
    @IBOutlet weak var requestLabel: UILabel!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var serviceLabel: UILabel!
    @IBOutlet weak var jobBudgetLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var applyButton: UIButton!
    @IBOutlet weak var payNowButton: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var leaveJobButton: UIButton!
    var paymentBlockTime = 0
    var job:RequestListModal?
    var delegate:RequestListViewController?
    var countdownTimer: Timer?
    var remainingTime: Int = 0

    override func awakeFromNib() {
        super.awakeFromNib()
        
        bgView.layer.borderWidth = 1
        bgView.layer.borderColor = UIColor.black.cgColor
        bgView.layer.cornerRadius = 8
        applyButton.layer.cornerRadius = 4
        payNowButton.layer.cornerRadius = 4
        leaveJobButton.layer.cornerRadius = 4
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func applyButtonTapped(_ sender: Any) {
        self.delegate?.applyButtonTapped(job: job!)
    }
    
    @IBAction func payNowButtonTapped(_ sender: Any) {
        
        self.delegate?.paidToJob(job: job!)
    }
    
    @IBAction func leaveJobButtonTapped(_ sender: Any) {
        self.delegate?.leaveJobButtonTapped(job: job!)
    }
    
    func getAddressString(_ dict : RequestListModal) -> String {
        job = dict
        var addressString = ""
                
        if let city = dict.city, !city.isEmpty {
            addressString += city + ", "
        }
        if let state = dict.state, !state.isEmpty {
            addressString += state
        }

        
        // Trim trailing comma and space if they exist
        addressString = addressString.trimmingCharacters(in: CharacterSet(charactersIn: ", "))
        
        // Replace consecutive commas with a single comma
        addressString = addressString.replacingOccurrences(of: ", , ", with: ", ")
        
        return addressString
    }
    
    func startCountdownTimer(paymentBlockTime: Int, jobBudgetPrice: Double) {
        // Calculate remaining seconds
        let currentTime = Int(Date().timeIntervalSince1970)
        remainingTime = max(paymentBlockTime - currentTime, 0)

        // Update immediately
        updateTimerLabel()

        // Start timer
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if self.remainingTime > 0 {
                self.remainingTime -= 1
                self.updateTimerLabel()
            } else {
                self.countdownTimer?.invalidate()
                self.timerLabel.text = "Expired"
                self.timerLabel.isHidden = true
                self.applyButton.setTitle("APPLY IN $\(jobBudgetPrice)", for: .normal)
            }
        }
    }

    func updateTimerLabel() {
        let minutes = remainingTime / 60
        let seconds = remainingTime % 60
        if(minutes > 0){
            timerLabel.text = String(format: "%d min %d sec", minutes, seconds)
        }
        else{
            timerLabel.text = String(format: "%d sec", seconds)
        }
        
    }
    
    func  commonInit(_ dict : RequestListModal, _ dele : RequestListViewController){
        countdownTimer?.invalidate()
        self.delegate = dele
        requestLabel.text = "Request ID : \(dict.reqDispId ?? "")"
        nameLabel.text = dict.name
        addressLabel.text = getAddressString(dict)
        dateLabel.text = AppUtility.getDateFromTimeEstime(dict.requestDate ?? 0.0)
        serviceLabel.text = dict.typeOfService
        jobBudgetLabel.text = "Purposed Budget : \(dict.jobBudgetLabel ?? "")"
        paymentBlockTime = Int(dict.paymentBlockTime ?? 0)
        applyButton.isHidden = true
        payNowButton.isHidden = true
        leaveJobButton.isHidden = true
        timerLabel.isHidden = true
        paymentBlockTime = 0
        var jobDeclined = false
        
        let drivers = dict.declineDrivers?.filter({ item  in
            item.driverId == CurrentUserInfo.userId
        })
        
        if(drivers != nil && drivers!.count > 0){
            jobDeclined = true
        }
        
        if let paymentTime = dict.paymentBlockTime {
            paymentBlockTime = Int(paymentTime)
        }
        
        if(dict.jobStatus == 0){
            if(jobDeclined){
                timerLabel.isHidden = false
                timerLabel.text = "You have declined this job."
            }
            else{
                //No Payment Block Case
                applyButton.isHidden = false
                applyButton.setTitle("APPLY IN $\(dict.jobBudgetPrice ?? 0.0)", for: .normal)
            }
        }
        else if(dict.jobStatus == 1){
            if(Int(paymentBlockTime) > Int(Date().timeIntervalSince1970)){
                if (dict.pendingPaymentDriverId == CurrentUserInfo.userId){
                    //Payment Block but not paid
                    timerLabel.isHidden = false
                    payNowButton.isHidden = false
                    payNowButton.setTitle("APP FEE TO CONNECT($\(dict.jobBudgetPrice ?? 0.0))", for: .normal)
                    startCountdownTimer(paymentBlockTime: paymentBlockTime, jobBudgetPrice: dict.jobBudgetPrice ?? 0.0)
                }
                else{
                    timerLabel.isHidden = false
                    timerLabel.text = "Pending Provider Bid"
                }
            }else{
                if(jobDeclined){
                    timerLabel.isHidden = false
                    timerLabel.text = "You have declined this job."
                }
                else{
                    applyButton.isHidden = false
                    applyButton.setTitle("APPLY IN $\(dict.jobBudgetPrice ?? 0.0)", for: .normal)
                }
            }
        }
        else if(dict.jobStatus == 2){
            if(dict.paidPaymentDriverId != CurrentUserInfo.userId){
                timerLabel.isHidden = false
                timerLabel.text = "Pending Provider Acceptance"
            }
            else{
                leaveJobButton.isHidden = false
                timerLabel.isHidden = false
                timerLabel.text = "Application Fee Paid ($\(dict.jobBudgetPrice ?? 0.0))"
            }
        }
        else{
            applyButton.isHidden = false
        }
        
        
        
    }
}
