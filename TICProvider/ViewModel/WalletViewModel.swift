
import Foundation
import ObjectMapper

enum WalletError: Error {
    case invalidURL
    case mappingFailed
    case server(statusCode: Int, message: String?)
    case network(String?)
}

struct WalletDriverResponse: Mappable {
    var driver: DriverModel = .init()
    var transactions: [TransactionModel] = []

    init?(map: Map) { }
    init() { }

    mutating func mapping(map: Map) {
        driver        <- map["driver"]
        transactions  <- map["transactions"]
        // Sort by tranDate DESC just once on mapping
        transactions.sort { $0.tranDate > $1.tranDate }
    }
}

struct DriverModel: Mappable {
    var subscriptionActive: Int = 0
    var subscriptionEndDate: Int = 0  // Unix seconds
    var subscriptionDevice: String?
    var totalCredit: Int = 0

    init?(map: Map) { }
    init() { }

    mutating func mapping(map: Map) {
        subscriptionActive   <- map["subscriptionActive"]
        subscriptionEndDate  <- map["subscriptionEndDate"]
        subscriptionDevice   <- map["subscriptionDevice"]
        totalCredit          <- map["totalCredit"]
    }

    // Convenience
    var isSubscriptionActive: Bool { subscriptionActive == 1 }
    var subscriptionEndDateObj: Date { Date(timeIntervalSince1970: TimeInterval(subscriptionEndDate)) }
}

struct TransactionModel: Mappable {
    var credit: Int = 0
    var tranDate: Int = 0   // Unix seconds
    var desc: String?
    var reqDispId: String?

    init?(map: Map) { }
    init() { }

    mutating func mapping(map: Map) {
        credit        <- map["credit"]
        tranDate      <- map["tranDate"]
        desc          <- map["desc"]
        reqDispId     <- map["reqDispId"]
        
        // Remove leading '#' if present
        if let id = reqDispId, id.hasPrefix("#") {
            reqDispId = String(id.dropFirst())
        }
    }

    // Convenience
    var date: Date { Date(timeIntervalSince1970: TimeInterval(tranDate)) }
    func formattedTranDate(dateStyle: DateFormatter.Style = .medium) -> String {
        let df = DateFormatter()
        df.dateStyle = dateStyle
        df.timeStyle = .none
        return df.string(from: date)
    }
}

// MARK: - ViewModel

class WalletViewModel {
    // Exposed state (bind to UI if you want)
    private(set) var driver: DriverModel = .init()
    private(set) var transactions: [TransactionModel] = []
    
    // New flags
    private(set) var isLoading: Bool = false
    private(set) var reachedEnd: Bool = false

    // Call this before a fresh fetch (pull-to-refresh)
    func resetPagination() {
        transactions.removeAll()
        reachedEnd = false
    }
    
    /// Fetch wallet and return via Result. Always returns on main thread.
    func getWallet(apiEndPoint: String, showLoader: Bool = true, completion: @escaping (Result<WalletDriverResponse, WalletError>) -> Void) {
        if isLoading || reachedEnd { return }
        isLoading = true
        
        let base = Configuration().environment.baseURL
        guard var comps = URLComponents(string: base + apiEndPoint) else {
            isLoading = false
            DispatchQueue.main.async { completion(.failure(.invalidURL)) }
            return
        }

        // Build query items from `params`
        var query: [URLQueryItem] = []

        // Auto-cursor: only when we already have items
        let shouldAppend = !transactions.isEmpty
        if shouldAppend, let lastTranDate = transactions.last?.tranDate {
            query.append(URLQueryItem(name: "tranDate", value: String(lastTranDate)))
        }

        comps.queryItems = query
        guard let url = comps.url else {
            isLoading = false
            DispatchQueue.main.async { completion(.failure(.invalidURL)) }
            return
        }

        NetworkManager.shared.getRequest(url,showLoader,"",networkHandler: {response,statusCode in
            defer { self.isLoading = false }
            APIHelper.parseObject(response,true) {payload,status,message,code in
                if status {
                    if let mapped = Mapper<WalletDriverResponse>().map(JSON: payload) {
                        // cache into view model state
                        self.driver = mapped.driver
                        
                        if(mapped.transactions.count == 0){
                            self.reachedEnd = true
                        }
                        if shouldAppend {
                            self.transactions.append(contentsOf: mapped.transactions)
                        } else {
                            self.transactions = mapped.transactions
                        }
                        DispatchQueue.main.async {
                            completion(.success(mapped))
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(.failure(.mappingFailed))
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(.server(statusCode: statusCode,message: message)))
                    }
                }
            }
        })
    }

    // Helpers for UI
    var totalCreditText: String { "\(driver.totalCredit)" }
    func formattedSubscriptionEndDate(dateStyle: DateFormatter.Style = .medium) -> String {
        let df = DateFormatter()
        df.dateStyle = dateStyle
        df.timeStyle = .none
        return df.string(from: driver.subscriptionEndDateObj)
    }
}
