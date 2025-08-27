import Foundation

struct Config {
    static let shared = Config()
    
    private init() {}
    
    var transitAPIKey: String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let apiKey = plist["TRANSIT_API_KEY"] as? String else {
            fatalError("Config.plist not found or TRANSIT_API_KEY not set")
        }
        return apiKey
    }
}

