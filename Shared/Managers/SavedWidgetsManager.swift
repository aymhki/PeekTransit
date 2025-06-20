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
        
        guard let sharedDefaults = SharedDefaults.userDefaults,
              let data = sharedDefaults.data(forKey: SharedDefaults.widgetsKey) else {
            return
        }
        
        do {
            let decoder = createJSONDecoder()
            let widgets = try decoder.decode([WidgetModel].self, from: data)
            savedWidgets = widgets
        } catch {
            do {
                let oldDecoder = JSONDecoder()
                let widgets = try oldDecoder.decode([WidgetModel].self, from: data)
                
                savedWidgets = widgets.map { oldWidget in
                    let migratedData = WidgetDataMigrator.migrateWidgetDataIfNeeded(oldWidget.widgetData)
                    return WidgetModel(widgetData: migratedData)
                }
                
                saveToDisk()
                
            } catch {
                savedWidgets = []
                sharedDefaults.removeObject(forKey: SharedDefaults.widgetsKey)
            }
        }
    }
    
    private func saveToDisk() {
        guard let sharedDefaults = SharedDefaults.userDefaults else {
            return
        }
        
        do {
            let encoder = createJSONEncoder()
            
            for (index, widget) in savedWidgets.enumerated() {
                do {
                    _ = try encoder.encode(widget)
                } catch {
                    let cleanedWidget = cleanWidget(widget)
                    savedWidgets[index] = cleanedWidget
                }
            }
            
            let encoded = try encoder.encode(savedWidgets)
            
            sharedDefaults.set(encoded, forKey: SharedDefaults.widgetsKey)
            
            
            WidgetCenter.shared.reloadAllTimelines()
            
        } catch {
            
            var successfulWidgets: [WidgetModel] = []
            let encoder = createJSONEncoder()
            
            for widget in savedWidgets {
                do {
                    _ = try encoder.encode(widget)
                    successfulWidgets.append(widget)
                } catch {
                   
                }
            }
            
            if successfulWidgets.count != savedWidgets.count {
                savedWidgets = successfulWidgets

                
                if let cleanedData = try? encoder.encode(successfulWidgets) {
                    sharedDefaults.set(cleanedData, forKey: SharedDefaults.widgetsKey)
                }
            }
        }
    }
    
    private func createJSONEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.nonConformingFloatEncodingStrategy = .convertToString(
            positiveInfinity: "infinity",
            negativeInfinity: "-infinity",
            nan: "nan"
        )
        return encoder
    }
    
    private func createJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: "infinity",
            negativeInfinity: "-infinity",
            nan: "nan"
        )
        return decoder
    }
    
    private func cleanWidget(_ widget: WidgetModel) -> WidgetModel {
        var cleanedData: [String: Any] = [:]
        
        for (key, value) in widget.widgetData {
            if isEncodable(value) {
                cleanedData[key] = value
            } else {
                cleanedData[key] = String(describing: value)
            }
        }
        
        return WidgetModel(widgetData: cleanedData)
    }
    
    private func isEncodable(_ value: Any) -> Bool {
        do {
            let encoder = createJSONEncoder()
            _ = try encoder.encode(AnyCodable(value))
            return true
        } catch {
            return false
        }
    }
    
    func deleteWidget(for widgetData: [String: Any]) {
        guard let widgetId = widgetData["id"] as? String else {
            savedWidgets = []
            saveToDisk()
            return
        }
        
        if let index = savedWidgets.firstIndex(where: {$0.id == widgetId }) {
            savedWidgets.remove(at: index)
        }
        
        saveToDisk()
    }
    
    func addWidget(_ widget: WidgetModel) {
        do {
            let encoder = createJSONEncoder()
            _ = try encoder.encode(widget)
            savedWidgets.append(widget)
            saveToDisk()
        } catch {
            let cleanedWidget = cleanWidget(widget)
            savedWidgets.append(cleanedWidget)
            saveToDisk()
        }
    }
    
    func hasWidgetWithName(_ name: String) -> Bool {
        return savedWidgets.contains { $0.name == name }
    }
    
    func countLockscreenWidgets() -> Int {
        return savedWidgets.filter { ($0.widgetData["size"] as? String) == "lockscreen" }.count
    }
    
    func updateWidget(_ id: String, with newData: [String: Any]) {
        if let index = savedWidgets.firstIndex(where: { $0.id == id }) {
            let newWidget = WidgetModel(widgetData: newData)
            
            do {
                let encoder = createJSONEncoder()
                _ = try encoder.encode(newWidget)
                savedWidgets[index] = newWidget
            } catch {
                let cleanedWidget = cleanWidget(newWidget)
                savedWidgets[index] = cleanedWidget
            }
            
            saveToDisk()
        }
    }
}
