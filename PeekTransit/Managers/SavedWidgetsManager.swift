import SwiftUI
import CoreLocation
import Foundation

class SavedWidgetsManager: ObservableObject {
    static let shared = SavedWidgetsManager()
    
    @Published private(set) var savedWidgets: [WidgetModel] = []
    @Published private(set) var isLoading = false
    
    private let userDefaultsKey = "savedWidgets"
    
    private init() {
        loadSavedWidgets()
    }
    
    func loadSavedWidgets() {
        isLoading = true
        defer { isLoading = false }
        
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let widgets = try? JSONDecoder().decode([WidgetModel].self, from: data) {
            savedWidgets = widgets
        }
    }
    
    private func saveToDisk() {
        if let encoded = try? JSONEncoder().encode(savedWidgets) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    func deleteWidget(for widgetData: [String: Any]) {
        guard let widgetId = widgetData["id"] as? String else { return }
        
        if let index = savedWidgets.firstIndex(where: {$0.id == widgetId }) {
            savedWidgets.remove(at: index)
        } else {
            print("Could not find widget data to delete:\n\(widgetData)\n")
        }
        
        saveToDisk()
    }
    
    func addWidget(_ widget: WidgetModel) {
        savedWidgets.append(widget)
        saveToDisk()
    }
}
