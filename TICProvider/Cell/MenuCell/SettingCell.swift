//
//  SettingCell.swift
//  Soliterra
//
//  Created by Ramniwas Easyeat on 04/02/23.
//

import UIKit

class SettingCell: ReusableTableViewCell {
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var img: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func commonInit(_ dict : SettingModel){
        img.image = dict.image
        img.tintColor = UIColor(red: 209.0/255.0, green: 232.0/255.0, blue: 195.0/255.0, alpha: 1.0) 
        lblName.text = dict.name
        
    }
    
}
