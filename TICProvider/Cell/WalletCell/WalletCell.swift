//
//  WalletCell.swift
//  TICProvider
//
//  Created by vineet patidar on 13/09/25.
//

import UIKit

class WalletCell: ReusableTableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var creditLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        bgView.layer.borderWidth = 1
        bgView.layer.borderColor = UIColor.black.cgColor
        bgView.layer.cornerRadius = 8
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    
    func  commonInit(_ dict : TransactionModel, _ index : Int){
        nameLabel.text = "ID #\(index)"
        if(dict.reqDispId != nil){
            nameLabel.text = nameLabel.text! + " (\(dict.reqDispId ?? "TAPIC"))"
        }
        
        dateLabel.text = dict.formattedTranDate(dateStyle: .medium)
        creditLabel.text = "\(dict.credit)"
        descLabel.text = dict.desc
        creditLabel.textColor = hexStringToUIColor("77B255")
        if(dict.credit < 0){
            creditLabel.textColor = hexStringToUIColor("C837AB")
        }
    }
}
