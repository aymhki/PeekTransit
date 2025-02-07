import SwiftUI


class VariantsCacheManager {
    static let shared = VariantsCacheManager()
    private let defaults = UserDefaults.standard
    private let cacheKey = "transit_variants_cache"
    private let lastUpdateKey = "transit_variants_last_update"
    
    private var cache: [String: [[String: Any]]] {
        get {
            if let data = defaults.data(forKey: cacheKey),
               let cache = try? JSONSerialization.jsonObject(with: data) as? [String: [[String: Any]]] {
                return cache
            }
            return [:]
        }
        set {
            if let data = try? JSONSerialization.data(withJSONObject: newValue) {
                defaults.set(data, forKey: cacheKey)
            }
        }
    }
    
    func getCachedVariants(for stopNumber: Int) -> [[String: Any]]? {
        return cache[String(stopNumber)]
    }
    
    func cacheVariants(_ variants: [[String: Any]], for stopNumber: Int) {
        var currentCache = cache
        currentCache[String(stopNumber)] = variants
        cache = currentCache
    }
    
    func clearAllCaches() {
        defaults.removeObject(forKey: cacheKey)
    }
}

