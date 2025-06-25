//
//  SubscriptionManager.swift
//  MMAI-iOS
//
//  Created by vineet patidar on 12/12/24.
//





import ObjectiveC
import StoreKit

protocol SubscriptionManagerDelegate: AnyObject {
    func subscriptionManagerDidFetchProducts(_ manager: SubscriptionManager, products: [SKProduct])
    func subscriptionManager(_ manager: SubscriptionManager, didFailWithError error: Error)
}

protocol SubscriptionManagerPurchaseDelegate: AnyObject {
    func subscriptionManagerDidCompletePurchase(_ manager: SubscriptionManager, productIdentifier: String, transactionID: String, receipt: String, originalTransactionId: String)
    // Called when a purchase fails
    func subscriptionManagerDidFailPurchase( _ manager: SubscriptionManager, productIdentifier: String?, error: Error )
    // Called when a purchase is restored
    func subscriptionManagerDidRestorePurchase( _ manager: SubscriptionManager, productIdentifier: String, transactionID: String,receipt: String, originalTransactionId: String)
}

class SubscriptionManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    static let shared = SubscriptionManager()
    // Add a weak delegate reference to prevent retain cycles
    weak var delegate: SubscriptionManagerDelegate?
    weak var purchaseDelegate: SubscriptionManagerPurchaseDelegate?
    private var productsRequest: SKProductsRequest?
    var availableProducts: [SKProduct] = []
    
    // Fetch available products
    func fetchProducts(productIdentifiers: Set<String>) {
        productsRequest?.cancel()
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest?.delegate = self
        productsRequest?.start()
    }

    // Called when products are received
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        availableProducts = response.products
        // Notify the delegate that products have been fetched
        delegate?.subscriptionManagerDidFetchProducts(self, products: availableProducts)
        
        // For debugging
        for product in response.products {
            print("Product found: \(product.localizedTitle) - \(product.price)")
        }
        
        if !response.invalidProductIdentifiers.isEmpty {
            print("Invalid product IDs: \(response.invalidProductIdentifiers)")
        }
    }

    // Handle errors
    func request(_ request: SKRequest, didFailWithError error: Error) {
        // Notify the delegate about the error
        delegate?.subscriptionManager(self, didFailWithError: error)
        
        print("Failed to fetch products: \(error.localizedDescription)")
    }

    // Start purchase
    func purchase(product: SKProduct) {
        guard SKPaymentQueue.canMakePayments() else {
            print("In-app purchases are disabled.")
            return
        }
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    // Observe payment queue transactions
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                // Handle successful purchase
                handlePurchasedTransaction(transaction)
                
            case .failed:
                // Handle failed purchase
                handleFailedTransaction(transaction)
                
            case .restored:
                // Handle restored purchase
                handleRestoredTransaction(transaction)
                
            case .purchasing, .deferred:
                break
            @unknown default:
                break
            }
        }
    }
    
    private func handlePurchasedTransaction(_ transaction: SKPaymentTransaction) {
        print("Purchase successful for \(transaction.payment.productIdentifier)!")

        // Finish the transaction so the UI doesn't show it as pending
        SKPaymentQueue.default().finishTransaction(transaction)
        
        // Extract transaction identifier
        guard let transactionID = transaction.transactionIdentifier else {
            print("No transaction identifier found.")
            return
        }
        print(  "Transaction State: \(transaction.transactionState)")
        print(  "Transaction identitfier: \(transaction.transactionIdentifier ?? "")")
        print(  "Original Transaction identitfier: \(transaction.original?.transactionIdentifier ?? "")")
        print(  "Transaction date: \(String(describing: transaction.transactionDate))")
        
        // Get the receipt data
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
              FileManager.default.fileExists(atPath: appStoreReceiptURL.path) else {
            print("No App Store receipt found.")
            return
        }
        
        do {
            let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
            let receiptString = receiptData.base64EncodedString(options: [])

            purchaseDelegate?.subscriptionManagerDidCompletePurchase(
                self,
                productIdentifier: transaction.payment.productIdentifier,
                transactionID: transactionID,
                receipt: receiptString,
                originalTransactionId: transaction.original?.transactionIdentifier ?? transactionID
            )
        } catch {
            print("Couldn't read receipt data: \(error.localizedDescription)")
        }
    }

    private func handleFailedTransaction(_ transaction: SKPaymentTransaction) {
        guard let error = transaction.error else {
            // No specific error info
            print("Purchase failed with unknown error.")
            // Finish transaction to remove it from the queue
            SKPaymentQueue.default().finishTransaction(transaction)
            return
        }
        print("Purchase failed: \(error.localizedDescription)")

        // Notify the delegate about the failure
        purchaseDelegate?.subscriptionManagerDidFailPurchase(
            self,
            productIdentifier: transaction.payment.productIdentifier,
            error: error
        )

        // Finish transaction to remove it from the queue
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func handleRestoredTransaction(_ transaction: SKPaymentTransaction) {
        print("Purchase restored for \(transaction.payment.productIdentifier)!")
        
        // Finish the transaction
        SKPaymentQueue.default().finishTransaction(transaction)
        
        guard let transactionID = transaction.transactionIdentifier else {
            print("No transaction identifier found on restore.")
            return
        }
        
        print(  "Transaction State: \(transaction.transactionState)")
        print(  "Transaction identitfier: \(transaction.transactionIdentifier ?? "")")
        print(  "Original Transaction identitfier: \(transaction.original?.transactionIdentifier ?? "")")
        print(  "Transaction date: \(String(describing: transaction.transactionDate))")
        
        // Get the receipt data for restored transaction
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
              FileManager.default.fileExists(atPath: appStoreReceiptURL.path) else {
            print("No App Store receipt found for restore.")
            return
        }
        
        do {
            let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
            let receiptString = receiptData.base64EncodedString(options: [])
            
            purchaseDelegate?.subscriptionManagerDidRestorePurchase(
                self,
                productIdentifier: transaction.payment.productIdentifier,
                transactionID: transactionID,
                receipt: receiptString,
                originalTransactionId: transaction.original?.transactionIdentifier ?? transactionID
            )
        } catch {
            print("Couldn't read receipt data for restore: \(error.localizedDescription)")
        }
    }
}
