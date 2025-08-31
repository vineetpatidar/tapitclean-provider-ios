
import Foundation
import UIKit
import ObjectMapper


struct RequestListModal : Mappable {
    
    
    var address : String?
    var address1 : String?
    var city : String?
    var country : String?
    var customerId : String?
    var desc : String?
    var latitude : Double?
    var longitude : Double?
    var name : String?
    var phoneNumber : String?
    var typeOfService : String?
    var state : String?
    var requestDate : Double?
    var requestId : String?
    var accepted : Bool = false
    var arrivalCode : String?
    var declineDrivers :[DeclineDrivers]?
    var declineReassignDrivers :[DeclineDrivers]?
    var driverArrived : Bool = false
    var driverArrivedDate : Double?
    var confirmArrival : Bool = false
    var confrimArrivalDate : Double?
    var confirmHandover : Bool = false
    var reqDispId : String?
    var cancelled : Bool = false
    var markNoShow : Bool = false
    var driverId : String?
    var driverName : String?
    var driverPhoneNumber : String?
    var cancelledDate : Double?
    var done : Bool = false
    var isRunning : Bool = false
    var isPending : Int = 1
    var requestCompletedDate : Double?
    var completed : Bool?
    var acceptedLoc : KIALocation?
    var acceptDriverList :[AcceptedDrivers]?
    var reassignAcceptDriverList :[AcceptedDrivers]?
    var landMark: String?
    var postalCode: String?
    var destinationAdd : DestinationAdd?
    var landmark : String?
    var isPendingSubStatus : Int = 0
    var reassignDriverList :[ReassignDriver]?
    var prevDriverLocation : DestinationAdd?
    var reassignRequestId: String?
    var reassignHistory: [ReassignHistory]?
    var pendingPaymentDriverId:String?
    var paymentBlockTime: Double?
    var paymentStatus: String?
    var jobStatus: Int = 0
    var jobBudgetLabel:String?
    var androidStoreId:String?
    var iosStoreId:String?
    var paidPaymentDriverId:String?
    var jobBudgetPrice: Double?
    var jobBudgetCredit: Int?
    init?(map: Map) {
        
    }
    
    mutating func mapping(map: Map) {
        address <- map["address"]
        address1 <- map["address1"]
        city <- map["city"]
        country <- map["country"]
        customerId <- map["customerId"]
        desc <- map["desc"]
        latitude <- map["latitude"]
        longitude <- map["longitude"]
        name <- map["name"]
        phoneNumber <- map["phoneNumber"]
        typeOfService <- map["typeOfService"]
        state <- map["state"]
        landMark <- map["landMark"]
        postalCode <- map["postalCode"]
        requestDate <- map["requestDate"]
        requestId <- map["requestId"]
        accepted <- map["accepted"]
        acceptedLoc <- map["acceptedLoc"]
        arrivalCode <- map["arrivalCode"]
        declineDrivers <- map["declineDrivers"]
        declineReassignDrivers <- map["declineReassignDrivers"]
        driverArrived <- map["driverArrived"]
        driverArrivedDate <- map["driverArrivedDate"]
        confirmArrival <- map["confirmArrival"]
        confrimArrivalDate <- map["confrimArrivalDate"]
        confirmHandover <- map["confirmHandover"]
        reqDispId <- map["reqDispId"]
        cancelled <- map["cancelled"]
        markNoShow <- map["markNoShow"]
        driverId <- map["driverId"]
        driverName <- map["driverName"]
        driverPhoneNumber <- map["driverPhoneNumber"]
        cancelledDate <- map["cancelledDate"]
        done <- map["done"]
        isPending <- map["isPending"]
        isRunning <- map["isRunning"]
        requestCompletedDate <- map["requestCompletedDate"]
        completed <- map["completed"]
        acceptDriverList <- map["acceptDriverList"]
        reassignAcceptDriverList <- map["reassignAcceptDriverList"]
        destinationAdd <- map["destinationAdd"]
        landmark <- map["landmark"]
        isPendingSubStatus <- map["isPendingSubStatus"]
        reassignDriverList <- map["reassignDriverList"]
        prevDriverLocation <- map["prevDriverLocation"]
        reassignRequestId <- map["reassignRequestId"]
        reassignHistory <- map["reassignHistory"]
        pendingPaymentDriverId <- map["pendingPaymentDriverId"]
        paymentBlockTime <- map["paymentBlockTime"]
        paymentStatus <- map["paymentStatus"]
        jobStatus <- map["jobStatus"]
        jobBudgetLabel <- map["jobBudgetLabel"]
        jobBudgetPrice <- map["jobBudgetPrice"]
        jobBudgetCredit <- map["jobBudgetCredit"]
        androidStoreId <- map["androidStoreId"]
        iosStoreId <- map["iosStoreId"]
        paidPaymentDriverId <- map["paidPaymentDriverId"]
    }
}

struct LeaveJobModal : Mappable {
    
    var request : RequestListModal?
    var driver : ProfileResponseModel?
    init?(map: Map) {
        
    }
    
    mutating func mapping(map: Map) {
        request <- map["request"]
        driver <- map["driver"]
    }
}

struct KIALocation : Mappable {
    var  lng : Double = 0
    var lat : Double = 0
    
    init?(map: Map) {
        lng = 0
        lat = 0
    }
    
    mutating func mapping(map: Map) {
        lng <- map["lng"]
        lat <- map["lat"]
    }
}

struct DeclineDrivers : Mappable {
    
    var  driverId : String?
    var date : String?
    
    init?(map: Map) {
        
    }
    
    mutating func mapping(map: Map) {
        driverId <- map["driverId"]
        date <- map["date"]
    }
}

struct AcceptedDrivers : Mappable {
    var  driverId : String?
    
    init?(map: Map) {
        
    }
    
    mutating func mapping(map: Map) {
        driverId <- map["driverId"]
    }
}

struct ReassignDriver : Mappable {
    var driverId : String?
    var reassignDate : Double?
    
    init?(map: Map) {
        
    }
    
    mutating func mapping(map: Map) {
        driverId <- map["driverId"]
        reassignDate <- map["reassignDate"]
    }
}

struct ReassignHistory : Mappable {
    var  reassignRequestId : String?
    var driverId : String?
    var driverName : String?
    var driverPhoneNumber : String?
    init?(map: Map) {
        
    }
    
    mutating func mapping(map: Map) {
        reassignRequestId <- map["reassignRequestId"]
        driverId <- map["driverId"]
        driverName <- map["driverName"]
        driverPhoneNumber <- map["driverPhoneNumber"]
    }
}

struct DestinationAdd : Mappable {
    var  address : String?
    var  address1 : String?
    var  city : String?
    var  country : String?
    var  state : String?
    var  landmark : String?
    var  postalCode : String?
    var latitude : Double?
    var longitude : Double?

    init?(map: Map) {
        
    }
    
    mutating func mapping(map: Map) {
        address <- map["address"]
        address1 <- map["address1"]
        city <- map["city"]
        country <- map["country"]
        state <- map["state"]
        postalCode <- map["postalCode"]
        landmark <- map["landmark"]
        latitude <- map["latitude"]
        longitude <- map["longitude"]
    }
}

class RequestListViewModal {
    
    var requestModel : RequestModel?
    var listArray = [RequestListModal]()
    let defaultCellHeight = 136
    var errorMessage: String?
    var errorCode: Int = 0
    var successMessage: String?
    
    func sendRequest(_ apiEndPoint: String, handler: @escaping ([RequestListModal],Int) -> Void) {
        
        guard let url = URL(string: Configuration().environment.baseURL + apiEndPoint) else {return}
        NetworkManager.shared.getRequest(url, true, "", networkHandler: {(responce,statusCode) in
            if(statusCode == 200){
                let dictResponce =  Mapper<RequestListModal>().mapArray(JSONArray: responce["payload"] as! [[String : Any]])
                handler(dictResponce,statusCode)
            }
            
            else{
                DispatchQueue.main.async {
                    Alert(title: "", message: "", vc: RootViewController.controller!)
                }
                
            }
        })
    }
    
    func applyRequest(_ apiEndPoint: String, _ param : [String : Any], handler: @escaping (RequestListModal?,Int) -> Void) {
        
        guard let url = URL(string: Configuration().environment.baseURL + apiEndPoint) else {return}
        NetworkManager.shared.postRequest(url, true, "",params:param, networkHandler: {(responce,statusCode) in
            APIHelper.parseObject(responce, false) { payload, status, message, code in
                if status {
                    self.successMessage = message
                    let dictResponce =  Mapper<RequestListModal>().map(JSON: payload)
                    
//                    need to replace dictResponce in this array common field is requestId
                    if let updatedItem = dictResponce {
                        if let index = self.listArray.firstIndex(where: { $0.requestId == updatedItem.requestId }) {
                            self.listArray[index] = updatedItem
                        }
                    }
                    handler(dictResponce!,0)
                }
                else{
                    self.errorMessage = message
                    handler(nil,-1)
                    DispatchQueue.main.async {
                        Alert(title: "", message: message, vc: RootViewController.controller!)
                    }
                }
            }
        })
    }
    
    func leaveRequest(_ apiEndPoint: String, _ param : [String : Any], handler: @escaping (LeaveJobModal?,Int) -> Void) {
        
        guard let url = URL(string: Configuration().environment.baseURL + apiEndPoint) else {return}
        NetworkManager.shared.postRequest(url, true, "",params:param, networkHandler: {(responce,statusCode) in
            APIHelper.parseObject(responce, false) { payload, status, message, code in
                if status {
                    self.successMessage = message
                    let dictResponce =  Mapper<LeaveJobModal>().map(JSON: payload)
//                  need to replace dictResponce in this array common field is requestId
                    if let updatedItem = dictResponce?.request {
                        
                        if let index = self.listArray.firstIndex(where: { $0.requestId == updatedItem.requestId }) {
                            self.listArray[index] = updatedItem
                        }
                    }
                    handler(dictResponce!,0)
                }
                else{
                    self.errorMessage = message
                    handler(nil,-1)
                    DispatchQueue.main.async {
                        Alert(title: "", message: message, vc: RootViewController.controller!)
                    }
                }
            }
        })
    }
    
    func addTopup(_ apiEndPoint: String,_ param : [String : Any], handler: @escaping (LeaveJobModal?,Int) -> Void) {
        guard let url = URL(string: Configuration().environment.baseURL + apiEndPoint) else {return}
        NetworkManager.shared.postRequest(url, true, "", params:param, networkHandler: {(responce,statusCode) in
//            print(responce)
            APIHelper.parseObject(responce, true) { payload, status, message, code in
                if status {
                    let dictResponce =  Mapper<LeaveJobModal>().map(JSON: payload)
//                  need to replace dictResponce in this array common field is requestId
                    if let updatedItem = dictResponce?.request {
                        
                        if let index = self.listArray.firstIndex(where: { $0.requestId == updatedItem.requestId }) {
                            self.listArray[index] = updatedItem
                        }
                    }
                    handler(dictResponce!,0)
                }
                else{
                    handler(nil,-1)
                }
            }
        })
    }
    
    

    
    
}
