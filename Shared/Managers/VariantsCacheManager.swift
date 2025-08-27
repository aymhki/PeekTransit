import SwiftUI

class VariantsCacheManager {
    static let shared = VariantsCacheManager()
    private let defaults = UserDefaults.standard
    private let cacheKey = "transit_variants_cache"
    private let lastUpdateKey = "transit_variants_last_update"
    
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
        return cache[String(stopNumber)]
    }
    
    func cacheVariants(_ variants: [Variant], for stopNumber: Int) {
        var currentCache = cache
        currentCache[String(stopNumber)] = variants
        cache = currentCache
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

