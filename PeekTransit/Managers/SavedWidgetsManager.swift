import SwiftUI
import CoreLocation
import Foundation
import WidgetKit



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
        
        if let sharedDefaults = SharedDefaults.userDefaults,
           let data = sharedDefaults.data(forKey: SharedDefaults.widgetsKey),
           let widgets = try? JSONDecoder().decode([WidgetModel].self, from: data) {
            savedWidgets = widgets
        }
    }
    
    private func saveToDisk() {
        print("Attempting to save widgets to disk")
        if let encoded = try? JSONEncoder().encode(savedWidgets),
           let sharedDefaults = SharedDefaults.userDefaults {
            print("Successfully encoded widgets")
            sharedDefaults.set(encoded, forKey: SharedDefaults.widgetsKey)
            print("Saved \(savedWidgets.count) widgets to SharedDefaults")
        } else {
            print("Failed to access SharedDefaults for saving") // Debug log
        }
        
        //WidgetCenter.shared.reloadAllTimelines()
        
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
