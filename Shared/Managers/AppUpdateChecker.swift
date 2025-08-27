
import SwiftUI
import StoreKit

struct AppUpdateChecker {
    func checkForUpdate() async {
        do {
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            
            let appStoreURL = URL(string: "https://itunes.apple.com/lookup?bundleId=\(Bundle.main.bundleIdentifier ?? "")&date=\(Date.init().timeIntervalSince1970)&country=ca")!
            let (data, _) = try await URLSession.shared.data(from: appStoreURL)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]],
               let appStoreVersion = results.first?["version"] as? String {
                
                let isUpdateAvailable = compareVersions(appStoreVersion, currentVersion)
                                
                if isUpdateAvailable {
                    NotificationCenter.default.post(name: .appUpdateAvailable, object: nil)
                }
            }
        } catch {
            print("Error checking for app update: \(error)")
        }
    }
    
    private func compareVersions(_ appStoreVersion: String, _ currentVersion: String) -> Bool {
        let appStoreComponents = appStoreVersion.components(separatedBy: ".").compactMap { Int($0) }
        let currentComponents = currentVersion.components(separatedBy: ".").compactMap { Int($0) }
        
        for i in 0..<min(appStoreComponents.count, currentComponents.count) {
            if appStoreComponents[i] > currentComponents[i] {
                return true
            } else if appStoreComponents[i] < currentComponents[i] {
                return false
            }
        }
        
        return appStoreComponents.count > currentComponents.count
    }
}


