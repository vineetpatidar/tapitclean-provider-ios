//
//  SubscriptionsCell.swift
//  MMAI-iOS
//
//  Created by vineet patidar on 15/12/24.
//

import UIKit

class SubscriptionsCell: UITableViewCell {
    
    @IBOutlet weak var lblPlanName: UILabel!
    @IBOutlet weak var lblDesc: UILabel!
    @IBOutlet weak var lblDesc2: UILabel!
    @IBOutlet weak var lblPrice: UILabel!
    @IBOutlet weak var btnPaid: UIButton!
    @IBOutlet weak var lblCurrentStatus: UILabel!
    static let identifier = "SubscriptionsCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.selectionStyle = .none
        // Configure the view for the selected state
    }
    
    @IBAction func btnPaid_Clicked(_ sender: Any) {
    }
    
    func configure(with item: PackageModel, isSubscription: Bool = false) {
        lblPlanName.text = item.title
        lblDesc.text = item.desc
        var priceText = item.appstorePrice

        if(item.appstorePrice != ""){
            btnPaid.titleLabel?.text = "Pay \(item.appstorePrice)"
            btnPaid.setTitle("Pay \(item.appstorePrice)", for: .normal)
        }
        else{
            priceText = "$\(item.value)"
            btnPaid.titleLabel?.text = "Pay $\(item.value)"
            btnPaid.setTitle("Pay $\(item.value)", for: .normal)
        }
        
        if(isSubscription){
            lblPrice.text = "\(priceText) / weekly"
        }
        else{
            lblPrice.text = priceText
        }
    }
}


