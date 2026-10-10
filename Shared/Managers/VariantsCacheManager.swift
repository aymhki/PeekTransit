import SwiftUI

class VariantsCacheManager {
    static let shared = VariantsCacheManager()
    private let defaults = UserDefaults.standard
    private let cacheKey = "transit_variants_cache"
    private let lastUpdateKey = "transit_variants_last_update"
    private let timestampsKey = "transit_variants_cache_timestamps"
    
    private var timestamps: [String: Date] {
        get {
            guard let data = defaults.data(forKey: timestampsKey),
                  let decodedTimestamps = try? JSONDecoder().decode([String: Date].self, from: data) else {
                return [:]
            }
            
            return decodedTimestamps
        }
        
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: timestampsKey)
            }
        }
    }
    
    private var cache: [String: [Variant]] {
        get {
            if let data = defaults.data(forKey: cacheKey) {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let decodedCache = try decoder.decode([String: [Variant]].self, from: data)
                    return decodedCache
                } catch {
                    print("Failed to decode cache: \(error)")
                    return [:]
                }
            } else {
                return [:]
            }
        }
        
        set {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(newValue)
                defaults.set(data, forKey: cacheKey)
            } catch {
                print("Failed to encode cache: \(error)")
            }
        }
    }
    
    func getCachedVariants(for stopNumber: Int) -> [Variant]? {
        let stopKey = String(stopNumber)
        
        guard let cachedAt = timestamps[stopKey],
              Date().timeIntervalSince(cachedAt) < getVariantsCacheMaxAgeSeconds() else {
            return nil
        }
        
        return cache[stopKey]
    }
    
    func cacheVariants(_ variants: [Variant], for stopNumber: Int) {
        let stopKey = String(stopNumber)
        
        var currentCache = cache
        currentCache[stopKey] = variants
        cache = currentCache
        
        var currentTimestamps = timestamps
        currentTimestamps[stopKey] = Date()
        timestamps = currentTimestamps
    }
    
    func clearAllCaches() {
        defaults.removeObject(forKey: cacheKey)
        defaults.removeObject(forKey: timestampsKey)
        defaults.removeObject(forKey: lastUpdateKey)
    }
    
    func getLastUpdateTime() -> Date? {
        return defaults.object(forKey: lastUpdateKey) as? Date
    }
    
    func updateLastUpdateTime() {
        defaults.set(Date(), forKey: lastUpdateKey)
    }
}



class RouteCacheManager {
    static let shared = RouteCacheManager()
    private let defaults = UserDefaults.standard
    private let cacheKey = "transit_route_cache"
    private let lastUpdateKey = "transit_route_last_update"
    
    private var cache: [String: Route] {
        get {
            if let data = defaults.data(forKey: cacheKey) {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let decodedCache = try decoder.decode([String: Route].self, from: data)
                    return decodedCache
                } catch {
                    print("Failed to decode route cache: \(error)")
                    return [:]
                }
            } else {
                return [:]
            }
        }
        
        set {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(newValue)
                defaults.set(data, forKey: cacheKey)
            } catch {
                print("Failed to encode route cache: \(error)")
            }
        }
        
    }
    
    
    func getCachedRoute(for routeKey: String) -> Route? {
        return cache[routeKey]
    }

    func cacheRoute(_ route: Route) {
        var currentCache = cache
        currentCache[route.key] = route
        cache = currentCache
    }
    
    func getAllCachedRoutes() -> [String: Route] {
        return cache
    }
    
    func clearAllCaches() {
        defaults.removeObject(forKey: cacheKey)
        defaults.removeObject(forKey: lastUpdateKey)
    }
    
    func getLastUpdateTime() -> Date? {
        return defaults.object(forKey: lastUpdateKey) as? Date
    }
    
    func updateLastUpdateTime() {
        defaults.set(Date(), forKey: lastUpdateKey)
    }
}

