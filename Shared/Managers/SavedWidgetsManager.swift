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
        if let encoded = try? JSONEncoder().encode(savedWidgets),
           let sharedDefaults = SharedDefaults.userDefaults {
            sharedDefaults.set(encoded, forKey: SharedDefaults.widgetsKey)
        }
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func deleteWidget(for widgetData: [String: Any]) {
        guard let widgetId = widgetData["id"] as? String else {
            savedWidgets = []
            saveToDisk()
            return
        }
        
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
    
    func hasWidgetWithName(_ name: String) -> Bool {
        return savedWidgets.contains { $0.name == name }
    }
    
    func countLockscreenWidgets() -> Int {
        return savedWidgets.filter { ($0.widgetData["size"] as? String) == "lockscreen" }.count
    }
    
    func updateWidget(_ id: String, with newData: [String: Any]) {
        if let index = savedWidgets.firstIndex(where: { $0.id == id }) {
            savedWidgets[index] = WidgetModel(widgetData: newData)
            saveToDisk()
        }
    }

}
