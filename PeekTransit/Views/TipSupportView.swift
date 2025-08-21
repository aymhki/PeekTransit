import SwiftUI
import StoreKit

struct TipSupportView: View {
    @StateObject private var storeManager = TipStoreManager.shared
    @State private var selectedAmount: TipAmount = .five
    @State private var makeMonthly = false
    @State private var customAmount = 1
    @State private var showingCustomAmount = false
    @State private var isProcessing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var activeSubscription: ActiveSubscription?
    @Environment(\.dismiss) private var dismiss
    @State private var isLoadingSubscription = true
    
    var body: some View {
        Group {
            if isLoadingSubscription {
                loadingView
            } else {
                proccesedView
            }
            
        }
        .navigationTitle("Support")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Tip Status", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .task {
            await loadInitialData()
        }
    }
    
    var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var processedViewHeader: some View {
        VStack (spacing: 16) {
            VStack(spacing: 16) {
                Image(systemName: activeSubscription != nil ? "heart.circle.fill" : "heart.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.pink)
                
                Text("Support Development")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let subscription = activeSubscription {
                    Text("Thank you for your ongoing monthly support! 💖")
                        .font(.body)
                        .foregroundColor(.pink)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else {
                    Text("Your support helps keep this app free and continuously improving. Every tip is greatly appreciated!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.top)
            
            if let subscription = activeSubscription {
                VStack(spacing: 16) {
                    Text("You can still send additional one-time tips below or change your monthly amount by selecting a different subscription.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    var processedViewAmountSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Amount")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach([TipAmount.three, TipAmount.five, TipAmount.ten], id: \.self) { amount in
                    TipAmountButton(
                        amount: amount,
                        isSelected: selectedAmount == amount,
                        product: storeManager.getProduct(for: amount, isSubscription: makeMonthly),
                        action: {
                            if !isCurrentSubscriptionAmount(amount) || !makeMonthly {
                                   selectedAmount = amount
                                   showingCustomAmount = false
                                   customAmount = 1
                            }
                        },
                        isCurrentSubscription: isCurrentSubscriptionAmount(amount),
                        makeMonthly: makeMonthly
                    )
                }
            }
            
            Button(action: {
                if !showingCustomAmount {
                    showingCustomAmount = true
                    selectedAmount = .custom
                    
                }
            }) {
                HStack {
                    Text("Custom Amount ($1-$20)")
                        .fontWeight(.medium)
                    Spacer()
                    if showingCustomAmount || selectedAmount == .custom {
                        StableCustomAmountPicker(
                            customAmount: $customAmount,
                            activeSubscription: activeSubscription
                        )
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedAmount == .custom ? Color.pink.opacity(0.1) : Color(UIColor.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedAmount == .custom ? Color.pink : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    var processedViewPurchaseMonthlyToggle: some View {
        VStack (spacing: 16) {
            if activeSubscription == nil {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $makeMonthly) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Make it monthly")
                                .font(.headline)
                            Text("Support ongoing development with a monthly contribution")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                    .tint(.pink)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
            } else {
                EmptyView()
            }
        }
    }
    
    var processedViewPurchaseButton: some View {
        Button(action: processTip) {
            HStack (spacing: 4) {
                if isProcessing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: getButtonIcon())
                }
                
                Text(getButtonText())
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(getButtonColor())
            )
        }
        .disabled(isProcessing || !canMakePurchase())
        .opacity(canMakePurchase() ? 1.0 : 0.6)
    }
    
    var proccesdViewDisclaimer: some View {
        VStack(spacing: 8) {
            Text("Tips are non-refundable. Monthly subscriptions can be cancelled anytime in your App Store settings. Prices automatically convert from CAD to your local currency.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if activeSubscription != nil {
                Text("If you wish to change or cancel your subscription, please visit App Store > Account > Subscriptions or visting the link below.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: openSubscriptionManagement) {
                    Text("Manage Subscription")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .underline()
                }
                
                Spacer()
            }
            
            
            
            HStack(spacing: 16) {
                Button(action: openTermsOfUse) {
                    Text("Terms of Use")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .underline()
                }
                
                Text("•")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: restorePurchases) {
                    Text("Restore Purchases")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .underline()
                }
            }
        }
    }
    
    var proccesedView: some View {
        ScrollView {
            VStack(spacing: 24) {
                processedViewHeader
                processedViewAmountSelectionSection
                processedViewPurchaseMonthlyToggle
                processedViewPurchaseButton
                proccesdViewDisclaimer
            }
            .padding()
        }
    }
    
    struct StableCustomAmountPicker: View {
        @Binding var customAmount: Int
        let activeSubscription: ActiveSubscription?
        
        @State private var availableAmounts: [Int] = []
        @State private var isExpanded = false
        
        var body: some View {
            VStack(alignment: .trailing, spacing: 0) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 8) {
                        Text("$\(customAmount)")
                            .fontWeight(.medium)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(UIColor.tertiarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                if isExpanded {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(availableAmounts, id: \.self) { amount in
                                Button(action: {
                                    customAmount = amount
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isExpanded = false
                                    }
                                }) {
                                    HStack {
                                        Text("$\(amount)")
                                            .foregroundColor(amount == customAmount ? .pink : .primary)
                                            .fontWeight(amount == customAmount ? .medium : .regular)
                                        
                                        Spacer()
                                        
                                        if amount == customAmount {
                                            Image(systemName: "checkmark")
                                                .font(.caption)
                                                .foregroundColor(.pink)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        Color(UIColor.tertiarySystemBackground)
                                            .opacity(amount == customAmount ? 0.5 : 0)
                                    )
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                
                                if amount != availableAmounts.last {
                                    Divider()
                                        .padding(.horizontal, 8)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(UIColor.tertiarySystemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                    ))
                    .zIndex(1)
                }
            }
            .onAppear {
                calculateAvailableAmounts()
            }
            .onChange(of: activeSubscription?.amount) { _ in
                calculateAvailableAmounts()
            }
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isExpanded {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded = false
                            }
                        }
                    }
            )
        }
        
        private func calculateAvailableAmounts() {
            let presetAmounts: Set<Int> = [3, 5, 10]
            var excludedAmounts = presetAmounts
            
            if let subscription = activeSubscription {
                excludedAmounts.insert(subscription.amount)
            }
            
            let newAvailableAmounts = Array(1...20).filter { !excludedAmounts.contains($0) }
            
            if availableAmounts != newAvailableAmounts {
                availableAmounts = newAvailableAmounts
                
                if !availableAmounts.contains(customAmount) && !availableAmounts.isEmpty {
                    customAmount = availableAmounts[0]
                }
            }
        }
    }
    
    private func loadInitialData() async {
        await storeManager.loadProducts()
        activeSubscription = await storeManager.checkSubscriptionStatus()
        isLoadingSubscription = false
        startTransactionListener()
        
        if activeSubscription != nil {
            makeMonthly = false
        }
    }
    
    private func isCurrentSubscriptionAmount(_ amount: TipAmount) -> Bool {
        guard let subscription = activeSubscription else { return false }
        return Int(amount.value) == subscription.amount
    }

        
    private func startTransactionListener() {
        Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)
                    await handleTransactionUpdate(transaction)
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    @MainActor
    private func handleTransactionUpdate(_ transaction: StoreKit.Transaction) async {
        if transaction.revocationDate == nil {
            let newSubscription = await storeManager.checkSubscriptionStatus()
            
            if newSubscription?.productId != activeSubscription?.productId {
                activeSubscription = newSubscription
                
                if activeSubscription != nil {
                    makeMonthly = false
                }
            }
        }
    }
    
    private func canMakePurchase() -> Bool {
        if selectedAmount == .custom {
            return customAmount >= 1 && customAmount <= 20
        }
        return true
    }
    
    private func processTip() {
        Task {
            await handleTipPurchase()
        }
    }
    
    @MainActor
    private func handleTipPurchase() async {
        isProcessing = true
        
        do {
            let success: Bool
            
            if activeSubscription != nil {
                makeMonthly = false
            }
            
            if selectedAmount == .custom {
                guard customAmount >= 1 && customAmount <= 20 else {
                    throw TipError.invalidAmount
                }
                
                
                success = try await storeManager.purchaseCustomTip(amount: customAmount, isSubscription: makeMonthly)
            } else {
                success = try await storeManager.purchaseTip(amount: selectedAmount, isSubscription: makeMonthly)
            }
            
            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.dismiss()
                }
            }
            
            
        } catch TipError.invalidAmount {
            alertMessage = "Invalid amount. Please enter a whole number between 1 and 20."
            showingAlert = true
        } catch TipError.purchaseFailed {
            alertMessage = "Purchase failed. Please try again later."
            showingAlert = true
        } catch TipError.productsNotLoaded {
            alertMessage = "Products not loaded. Please try again later."
            showingAlert = true
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
        
        isProcessing = false
    }
    
    private func getButtonIcon() -> String {
        if activeSubscription != nil && makeMonthly {
            return "arrow.triangle.2.circlepath"
        } else if makeMonthly {
            return "heart.fill"
        } else {
            return "heart.fill"
        }
    }
    
    private func getButtonText() -> String {
        if activeSubscription != nil && makeMonthly {
            return "Change Monthly Amount"
        } else if makeMonthly {
            return "Start Monthly Support"
        } else {
            return "Send Tip"
        }
    }
    
    private func getButtonColor() -> Color {
        if activeSubscription != nil && makeMonthly {
            return .orange
        } else {
            return .pink
        }
    }
    
    private func openSubscriptionManagement() {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.dismiss()
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            Task {
                try await AppStore.showManageSubscriptions(in: windowScene)
            }
        }
    }
    
    private func openTermsOfUse() {
        guard let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") else {
            return
        }
        UIApplication.shared.open(url)
    }

    private func restorePurchases() {
        Task {
            await handleRestorePurchases()
        }
    }
    
    @MainActor
    private func handleRestorePurchases() async {
        isProcessing = true
        isLoadingSubscription = true
        
        do {
            try await AppStore.sync()
            
            let newSubscription = await storeManager.checkSubscriptionStatus()
            activeSubscription = newSubscription
            
            if newSubscription != nil {
                alertMessage = "Purchases restored successfully! Your subscription has been activated."
            } else {
                let hasTips = await storeManager.hasBoughtTip()
                if hasTips {
                    alertMessage = "Purchases restored successfully!"
                } else {
                    alertMessage = "No previous purchases found to restore."
                }
            }
            
            showingAlert = true
            
        } catch {
            alertMessage = "Failed to restore purchases. Please try again later."
            showingAlert = true
        }
        
        isLoadingSubscription = false
        isProcessing = false
    }
}

struct TipAmountButton: View {
    let amount: TipAmount
    let isSelected: Bool
    let product: Product?
    let action: () -> Void
    let isCurrentSubscription: Bool
    let makeMonthly: Bool
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(amount.emoji)
                    .font(.title)
                
                if let product = product {
//                    Text(product.displayPrice)
//                        .font(.headline)
//                        .fontWeight(.semibold)
                    
                    Text(amount.fallbackPrice)
                        .font(.headline)
                        .fontWeight(.semibold)
                } else {
                    Text(amount.fallbackPrice)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text(amount.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.pink.opacity(0.1) : Color(UIColor.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isCurrentSubscription && makeMonthly)
        .opacity(isCurrentSubscription && makeMonthly ? 0.6 : 1.0)
    }
}

struct ActiveSubscription {
    let amount: Int
    let productId: String
    let nextBillingDate: Date
    let originalTransactionId: String
    let expirationDate: Date?
    let isActive: Bool 
}

enum TipAmount: CaseIterable, Hashable {
    case three, five, ten, custom
    
    var emoji: String {
        switch self {
        case .three: return "☕️"
        case .five: return "🥪"
        case .ten: return "🍕"
        case .custom: return "💝"
        }
    }
    
    var description: String {
        switch self {
        case .three: return "Coffee"
        case .five: return "Lunch"
        case .ten: return "Pizza"
        case .custom: return "Custom"
        }
    }
    
    var fallbackPrice: String {
        switch self {
        case .three: return "$3"
        case .five: return "$5"
        case .ten: return "$10"
        case .custom: return "Custom"
        }
    }
    
    var value: Double {
        switch self {
        case .three: return 3.0
        case .five: return 5.0
        case .ten: return 10.0
        case .custom: return 0.0
        }
    }
    
    var productIdentifier: String {
        switch self {
        case .three: return "tip_3_dollars"
        case .five: return "tip_5_dollars"
        case .ten: return "tip_10_dollars"
        case .custom: return "tip_custom"
        }
    }
    
    var subscriptionIdentifier: String {
        switch self {
        case .three: return "monthly_tip_3_dollars"
        case .five: return "monthly_default_tip_5_dollars"
        case .ten: return "monthly_tip_10_dollars"
        case .custom: return "monthly_tip_custom"
        }
    }
}

enum TipError: Error, LocalizedError {
    case invalidAmount
    case purchaseFailed
    case productsNotLoaded
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Please enter a whole number between 1 and 20"
        case .purchaseFailed:
            return "Purchase failed. Please try again."
        case .productsNotLoaded:
            return "Products not loaded. Please try again."
        }
    }
}

enum StoreError: Error {
    case failedVerification
}

