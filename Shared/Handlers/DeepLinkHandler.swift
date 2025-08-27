import SwiftUI

class DeepLinkHandler: ObservableObject {
    static let shared = DeepLinkHandler()
    
    @Published var selectedStopNumber: Int?
    @Published var isShowingBusStop = false
    @Published var lastDeepLinkTimestamp: Date? = nil
    
    private init() {}
    
    func handleURL(_ url: URL) {
        guard url.scheme == "peektransit" else {
            return
        }
        
        if url.host == "stop" {
            handleStopDeepLink(url)
        }
    }
    
    private func handleStopDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let stopNumberItem = components.queryItems?.first(where: { $0.name == "number" }),
              let stopNumber = Int(stopNumberItem.value ?? "") else {
            return
        }
        
        if self.selectedStopNumber == stopNumber && isShowingBusStop {
            self.lastDeepLinkTimestamp = Date()
        }
        
        self.selectedStopNumber = stopNumber
        self.isShowingBusStop = true
    }
    
    func reset() {
        selectedStopNumber = nil
        isShowingBusStop = false
    }
}
