

import Foundation
import UIKit
import ObjectMapper

class CouponCodeViewModal {
    var errorMessage: String?
    var errorCode: Int = 0
    var successMessage: String?
    
    func reedemCouponCode(_ apiEndPoint: String,_ param : [String : Any], handler: @escaping (ProfileResponseModel,Int) -> Void) {
        guard let url = URL(string: Configuration().environment.baseURL + apiEndPoint) else {return}
        NetworkManager.shared.postRequest(url, true, "", params:param, networkHandler: {(responce,statusCode) in
            print(responce)
            APIHelper.parseObject(responce, false) { payload, status, message, code in
                if status {
                    self.successMessage = message
                    let dictResponce =  Mapper<ProfileResponseModel>().map(JSON: payload)
                    handler(dictResponce!,0)
                }
                else{
                    self.errorMessage = message
                    handler(ProfileResponseModel(),-1)
                }
            }
        })
    }
    
}
