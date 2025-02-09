import SwiftUI

class DeepLinkHandler: ObservableObject {
    static let shared = DeepLinkHandler()
    @Published var selectedStopNumber: Int?
    @Published var isShowingBusStop = false
    
    private init() {}
    
    func handleURL(_ url: URL) {
        guard url.scheme == "peektransit",
              url.host == "stop",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let stopNumberItem = components.queryItems?.first(where: { $0.name == "number" }),
              let stopNumber = Int(stopNumberItem.value ?? "") else {
            return
        }
        
        selectedStopNumber = stopNumber
        isShowingBusStop = true
    }
}
