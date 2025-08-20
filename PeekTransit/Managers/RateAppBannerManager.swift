import Foundation

@MainActor
class RateAppBannerManager: ObservableObject {
    static let shared = RateAppBannerManager()
    
    @Published var shouldShowRateAppBanner = false
    @Published var hasShownRateAppBannerThisSession = false
    @Published var wasRateAppBannerManuallyHidden = false
    
    private let userDefaults = UserDefaults.standard
    private let rateAppShowCountKey = "rateAppShowCount"
    private let rateAppFirstShownDateKey = "rateAppFirstShownDate"
    private let rateAppLastShownDateKey = "rateAppLastShownDate"
    private let rateAppUserClickedKey = "rateAppUserClicked"
    
    private var appUsageStartTime: Date?
    private var rateAppTimer: Timer?
    
    private init() {}
    
    func startTrackingAppUsage() {
        appUsageStartTime = Date()
        startRateAppTimer()
    }
    
    func stopTrackingAppUsage() {
        rateAppTimer?.invalidate()
        rateAppTimer = nil
        appUsageStartTime = nil
    }
    
    func rateAppBannerWasTapped() {
        hasShownRateAppBannerThisSession = true
        shouldShowRateAppBanner = false
        wasRateAppBannerManuallyHidden = true
        userDefaults.set(true, forKey: rateAppUserClickedKey)
    }
    
    func hideRateAppBanner() {
        if wasRateAppBannerManuallyHidden {
            shouldShowRateAppBanner = false
        }
    }
    
    private func startRateAppTimer() {
        rateAppTimer = Timer.scheduledTimer(withTimeInterval: getUsageTimeToShowRateAppBannerAfterInSeconds(), repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.checkAndShowRateAppBanner()
            }
        }
    }
    
    private func checkAndShowRateAppBanner() {
        guard !hasShownRateAppBannerThisSession else { return }
        guard shouldShowBasedOnRules() else { return }
        shouldShowRateAppBanner = true
        incrementShowCount()
        userDefaults.set(Date(), forKey: rateAppLastShownDateKey)
    }
    
    private func shouldShowBasedOnRules() -> Bool {
        let showCount = userDefaults.integer(forKey: rateAppShowCountKey)
        let userHasClicked = userDefaults.bool(forKey: rateAppUserClickedKey)
        let lastShownDate = userDefaults.object(forKey: rateAppLastShownDateKey) as? Date
        let firstShownDate = userDefaults.object(forKey: rateAppFirstShownDateKey) as? Date
        
        if showCount == 0 {
            return true
        }
        
        if userHasClicked {
//            if let firstShown = firstShownDate {
//                let oneYearLater = Calendar.current.date(byAdding: .year, value: 1, to: firstShown) ?? firstShown
//                return Date() >= oneYearLater && showCount < getMaximumTimesToShowRateAppBanner()
//            }
            return false
        }
        
        if let lastShown = lastShownDate {
            let fourMonthsLater = Calendar.current.date(byAdding: .month, value: 4, to: lastShown) ?? lastShown
            return Date() >= fourMonthsLater && showCount < getMaximumTimesToShowRateAppBanner()
        }
        
        return false
    }
    
    private func incrementShowCount() {
        let currentCount = userDefaults.integer(forKey: rateAppShowCountKey)
        let newCount = currentCount + 1
        
        if currentCount == 0 {
            userDefaults.set(Date(), forKey: rateAppFirstShownDateKey)
        }
        
        userDefaults.set(newCount, forKey: rateAppShowCountKey)
        
    }
    
    func resetRateAppBannerData() {
        userDefaults.removeObject(forKey: rateAppShowCountKey)
        userDefaults.removeObject(forKey: rateAppFirstShownDateKey)
        userDefaults.removeObject(forKey: rateAppLastShownDateKey)
        userDefaults.removeObject(forKey: rateAppUserClickedKey)
        shouldShowRateAppBanner = false
        hasShownRateAppBannerThisSession = false
        wasRateAppBannerManuallyHidden = false
    }
    
    func getRateAppBannerStats() -> (showCount: Int, firstShown: Date?, lastShown: Date?, userClicked: Bool) {
        let showCount = userDefaults.integer(forKey: rateAppShowCountKey)
        let firstShown = userDefaults.object(forKey: rateAppFirstShownDateKey) as? Date
        let lastShown = userDefaults.object(forKey: rateAppLastShownDateKey) as? Date
        let userClicked = userDefaults.bool(forKey: rateAppUserClickedKey)
        return (showCount, firstShown, lastShown, userClicked)
    }
}
