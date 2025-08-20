import Foundation

@MainActor
class TipBannerManager: ObservableObject {
    static let shared = TipBannerManager()
    
    @Published var shouldShowTipBanner = false
    @Published var hasShownTipBannerThisSession = false
    @Published var wasTipBannerManuallyHidden = false
    
    private var storeManager = TipStoreManager.shared

    
    private let userDefaults = UserDefaults.standard
    private let tipBannerShowCountKey = "tipBannerShowCount"
    private let tipBannerFirstShownDateKey = "tipBannerFirstShownDate"
    private let tipBannerLastShownDateKey = "tipBannerLastShownDate"
    
    private var appUsageStartTime: Date?
    private var tipBannerTimer: Timer?
    
    private init() {}
        
    func startTrackingAppUsage() {
        appUsageStartTime = Date()
        startTipBannerTimer()
    }
    
    func stopTrackingAppUsage() {
        tipBannerTimer?.invalidate()
        tipBannerTimer = nil
        appUsageStartTime = nil
    }
    
    func tipBannerWasTapped() {
        hasShownTipBannerThisSession = true
        shouldShowTipBanner = false
        wasTipBannerManuallyHidden = true
        incrementShowCount()
    }
    
    func hideTipBanner() {
        if wasTipBannerManuallyHidden {
            shouldShowTipBanner = false
        }
    }
        
    private func startTipBannerTimer() {
        tipBannerTimer = Timer.scheduledTimer(withTimeInterval: getUsageTimeToShowTipBannerAfterInSeconds(), repeats: false) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                Task {
                    await self?.checkAndShowTipBanner()
                }
            }
        }
    }
    
    private func checkAndShowTipBanner() async {
        guard await !storeManager.hasBoughtTip() else { return }
        guard !hasShownTipBannerThisSession else { return }
        guard shouldShowBasedOnRules() else { return }
        shouldShowTipBanner = true
    }
    
    private func shouldShowBasedOnRules() -> Bool {
        let showCount = userDefaults.integer(forKey: tipBannerShowCountKey)
        let firstShownDate = userDefaults.object(forKey: tipBannerFirstShownDateKey) as? Date
        
        if showCount == 0 {
            return true
        }
        
        if showCount < getMaximumTimesToShowTipBanner() {
            return true
        }
        
        if let firstShown = firstShownDate {
            let oneYearLater = Calendar.current.date(byAdding: .year, value: 1, to: firstShown) ?? firstShown
            
            if (Date() >= oneYearLater) {
                resetTipBannerData()
                return true
            } else {
                return false
            }
        }
        
        return false
    }
    
    private func incrementShowCount() {
        let currentCount = userDefaults.integer(forKey: tipBannerShowCountKey)
        let newCount = currentCount + 1
        
        userDefaults.set(newCount, forKey: tipBannerShowCountKey)
        
        if currentCount == 0 {
            userDefaults.set(Date(), forKey: tipBannerFirstShownDateKey)
        }
        
        userDefaults.set(Date(), forKey: tipBannerLastShownDateKey)
    }
    
    
    func resetTipBannerData() {
        userDefaults.removeObject(forKey: tipBannerShowCountKey)
        userDefaults.removeObject(forKey: tipBannerFirstShownDateKey)
        userDefaults.removeObject(forKey: tipBannerLastShownDateKey)
        shouldShowTipBanner = false
        hasShownTipBannerThisSession = false
    }
    
    func getTipBannerStats() -> (showCount: Int, firstShown: Date?, lastShown: Date?) {
        let showCount = userDefaults.integer(forKey: tipBannerShowCountKey)
        let firstShown = userDefaults.object(forKey: tipBannerFirstShownDateKey) as? Date
        let lastShown = userDefaults.object(forKey: tipBannerLastShownDateKey) as? Date
        return (showCount, firstShown, lastShown)
    }
}



