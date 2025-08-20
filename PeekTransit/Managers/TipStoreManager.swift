import Foundation
import StoreKit

@MainActor
class TipStoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var subscriptions: [Product] = []
    
    static let shared = TipStoreManager()
    
    private let productIdentifiers: [String] = {
        return (1...20).map { "one_tip_\($0)_dollar" + ($0 == 1 ? "" : "s") }
    }()
    
    private let subscriptionIdentifiers: [String] = {
        return (1...20).map {
            $0 == 5 ? "monthly_default_tip_5_dollars" : "monthly_tip_\($0)_dollar" + ($0 == 1 ? "" : "s")
        }
    }()
    
    func loadProducts() async {
        do {
            let tipProducts = try await Product.products(for: productIdentifiers)
            self.products = tipProducts.sorted { $0.price < $1.price }
            
            let subscriptionProducts = try await Product.products(for: subscriptionIdentifiers)
            self.subscriptions = subscriptionProducts.sorted { $0.price < $1.price }
            
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func getProduct(for amount: TipAmount, isSubscription: Bool) -> Product? {
        let targetProducts = isSubscription ? subscriptions : products
        
        let identifier: String
        
        switch amount {
        case .three:
            identifier = isSubscription ? "monthly_tip_3_dollars" : "one_tip_3_dollars"
        case .five:
            identifier = isSubscription ? "monthly_default_tip_5_dollars" : "one_tip_5_dollars"
        case .ten:
            identifier = isSubscription ? "monthly_tip_10_dollars" : "one_tip_10_dollars"
        case .custom:
            return nil
        }
        
        return targetProducts.first { $0.id == identifier }
    }
    
    func getProductForCustomAmount(_ amount: Int, isSubscription: Bool) -> Product? {
        guard amount >= 1 && amount <= 20 else { return nil }
        
        let targetProducts = isSubscription ? subscriptions : products
        let identifier = isSubscription ? amount == 5 ? "monthly_default_tip_5_dollars" : "monthly_tip_\(amount)_dollar" + (amount == 1 ? "" : "s") : "one_tip_\(amount)_dollar" + (amount == 1 ? "" : "s")
        
        return targetProducts.first { $0.id == identifier }
    }
    
    func purchaseTip(amount: TipAmount, isSubscription: Bool) async throws -> Bool {
        guard let product = getProduct(for: amount, isSubscription: isSubscription) else {
            throw TipError.productsNotLoaded
        }
        
        return try await processPurchase(product: product)
    }
    
    func purchaseCustomTip(amount: Int, isSubscription: Bool) async throws -> Bool {
        guard let product = getProductForCustomAmount(amount, isSubscription: isSubscription) else {
            throw TipError.productsNotLoaded
        }
        
        return try await processPurchase(product: product)
    }
    
    private func processPurchase(product: Product) async throws -> Bool {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    return true
                case .unverified(_, let error):
                    print("Unverified transaction: \(error)")
                    throw TipError.purchaseFailed
                }
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                throw TipError.purchaseFailed
            }
            
        } catch StoreKitError.notEntitled {
            throw TipError.productsNotLoaded
        } catch StoreKitError.unsupported {
            throw TipError.purchaseFailed
        } catch {
            if let storeKitError = error as? StoreKitError {
                switch storeKitError {
                    case .userCancelled:
                        return false
                    default:
                        throw TipError.purchaseFailed
                }
            }
            
            throw TipError.purchaseFailed
        }
    }

    
    func checkSubscriptionStatus() async -> ActiveSubscription? {
        var activeSubscriptions: [ActiveSubscription] = []
        
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if subscriptionIdentifiers.contains(transaction.productID) {
                    let isNotExpired = transaction.expirationDate != nil && transaction.expirationDate! > Date()
                    
                    if isNotExpired {
                        let amount = extractAmountFromProductId(transaction.productID)
                        let nextBilling = transaction.expirationDate ?? Date()
                        
                        let isAutoRenewal = await checkAutoRenewalStatus(for: transaction.productID)
                        let isActive = isNotExpired && isAutoRenewal
                        
                        if isActive {
                            let subscription = ActiveSubscription(
                                amount: amount,
                                productId: transaction.productID,
                                nextBillingDate: nextBilling,
                                originalTransactionId: String(transaction.originalID),
                                expirationDate: transaction.expirationDate,
                                isActive: isActive,
                            )
                            
                            activeSubscriptions.append(subscription)
                        }
                    }
                }
                
            case .unverified(_, let error):
                continue
            }
        }
        
        return activeSubscriptions.max(by: { $0.nextBillingDate < $1.nextBillingDate })
    }
    


    private func checkAutoRenewalStatus(for productId: String) async -> Bool {
        do {
            let products = try await Product.products(for: [productId])
            guard let product = products.first,
                  let subscriptionInfo = product.subscription else {
                return true
            }
            
            let statuses = try await subscriptionInfo.status
            
            for status in statuses {
                if case .verified(let renewalInfo) = status.renewalInfo {
                    return renewalInfo.willAutoRenew
                }
            }
            
            return true
            
        } catch {
            print("Failed to check auto-renewal status: \(error)")
            return true
        }
    }


    
    
    func hasBoughtTip() async -> Bool {
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if productIdentifiers.contains(transaction.productID) || subscriptionIdentifiers.contains(transaction.productID) {
                    return true
                }
                
            case .unverified(_, _):
                continue
            }
        }
        
        return false
    }
    
    private func extractAmountFromProductId(_ productId: String) -> Int {
        let components = productId.components(separatedBy: "_")
        if components.count >= 4,
           let amount = Int(components[ productId.contains("_default_") ? 3 : 2]) {
            return amount
        }
        return 0
    }
}

extension TipStoreManager {
    func startTransactionListener() {
        Task {
            for await result in Transaction.updates {
                switch result {
                case .verified(let transaction):
                    await transaction.finish()
                case .unverified(_, let error):
                    continue
                }
            }
        }
    }
}


