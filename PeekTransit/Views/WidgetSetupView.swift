import SwiftUI
import Foundation
import CoreLocation
import AppIntents
import WidgetKit


struct WidgetSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()
    @State private var currentStep = 1
    @State private var selectedStops: [[String: Any]] = []
    @State private var selectedVariants: [String: [[String: Any]]] = [:]
    @State private var widgetSize = "medium"
    @State private var isClosestStop = false
    @State private var selectedTimeFormat: TimeFormat = .default
    @State private var slideOffset: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""
    @State private var widgetName: String = ""
    @State private var showLastUpdatedStatus = true

    private func generateDefaultWidgetName() -> String {
        if isClosestStop {
            return "Closest Stop - \(widgetSize)"
        } else {
            let stopNumbers = selectedStops.compactMap { stop -> String? in
                guard let number = stop["number"] as? Int else { return nil }
                return "#\(number)"
            }.joined(separator: ", ")
            
            let variantKeys = selectedVariants.values.flatMap { variants in
                variants.compactMap { $0["key"] as? String }
            }.joined(separator: ", ")
            
            return "\(stopNumbers) - \(variantKeys) - \(widgetSize) - \(selectedTimeFormat.rawValue) - \(showLastUpdatedStatus ? "Show Last Updated Status" : "Don't Show Last Updated Status")"
        }
    }


    
    private func createWidgetData() -> [String: Any] {
        var widgetData: [String: Any] = [
            "size": widgetSize,
            "id":  UUID().uuidString,
            "createdAt": ISO8601DateFormatter().string(from: Date()),
            "isClosestStop": isClosestStop,
            "name": widgetName.isEmpty ? generateDefaultWidgetName() : widgetName,
            "timeFormat": selectedTimeFormat.rawValue,
            "showLastUpdatedStatus": showLastUpdatedStatus
            
        ]
        
        if isClosestStop {
            widgetData["type"] = "closest_stop"
        } else {
            var stopsData: [[String: Any]] = []
            
            for stop in selectedStops {
                var stopData = stop
                if let stopNumber = stop["number"] as? Int,
                   let variants = selectedVariants[String(stopNumber)] {
                    stopData["selectedVariants"] = variants
                }
                stopsData.append(stopData)
            }
            
            widgetData["stops"] = stopsData
            widgetData["type"] = "multi_stop"
        }
        
        return widgetData
    }
    
    private func handleSave() {
        if widgetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            widgetName = generateDefaultWidgetName()
        }
        
        if SavedWidgetsManager.shared.hasWidgetWithName(widgetName) {
            saveErrorMessage = "A widget with this name already exists. Please choose a different name."
            showingSaveError = true
            return
        }
        
//        if widgetSize == "lockscreen" && SavedWidgetsManager.shared.countLockscreenWidgets() > 0 {
//            saveErrorMessage = "You can only have one lockscreen widget at a time."
//            showingSaveError = true
//            return
//        }
        
        let widgetData = createWidgetData()
        let widget = WidgetModel(widgetData: widgetData)
        SavedWidgetsManager.shared.addWidget(widget)
        dismiss()
    }
    
    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            opacity = 0
            slideOffset = -UIScreen.main.bounds.width
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if currentStep == 1 {
                if selectedStops.count > maxStopsAllowed {
                    selectedStops = Array(selectedStops.prefix(maxStopsAllowed))
                }
                selectedVariants = [:] 
            }
            
            currentStep += 1
            slideOffset = UIScreen.main.bounds.width
            
            withAnimation(.easeInOut(duration: 0.3)) {
                opacity = 1
                slideOffset = 0
            }
        }
    }
    
    private func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            opacity = 0
            slideOffset = UIScreen.main.bounds.width
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            switch currentStep {
            case 3:
                selectedVariants = [:]
            case 2:
                selectedStops = []
                selectedVariants = [:]
                isClosestStop = false
            default:
                break
            }
            
            currentStep -= 1
            slideOffset = -UIScreen.main.bounds.width
            
            withAnimation(.easeInOut(duration: 0.3)) {
                opacity = 1
                slideOffset = 0
            }
        }
    }
    
    private var shouldDisableNextButton: Bool {
        switch currentStep {
        case 1:
            return widgetSize.isEmpty
        case 2:
            return selectedStops.isEmpty && !isClosestStop
        case 3:
            if isClosestStop {
                return false
            }
            return !selectedStops.allSatisfy { stop in
                guard let stopNumber = stop["number"] as? Int else { return false }
                return selectedVariants[String(stopNumber)]?.isEmpty == false
            }
        default:
            return false
        }
    }
    
    private var maxStopsAllowed: Int {
        return getMaxSopsAllowed(widgetSizeSystemFormat: nil, widgetSizeStringFormat: widgetSize)
    }
    
    private var maxVariantsPerStop: Int {        
        return getMaxVariantsAllowed(widgetSizeSystemFormat: nil, widgetSizeStringFormat: widgetSize)
        
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Group {
                    switch currentStep {
                    case 1:
                        VStack {
                            SizeSelectionStep(selectedSize: $widgetSize, selectedTimeFormat: $selectedTimeFormat, showLastUpdatedStatus: $showLastUpdatedStatus)
                            
                            ContinueButton(
                                title: "Continue",
                                isDisabled: widgetSize.isEmpty,
                                action: nextStep
                            )
                        }
                    case 2:
                        VStack {
                            StopSelectionStep(
                                selectedStops: $selectedStops,
                                isClosestStop: $isClosestStop,
                                maxStopsAllowed: maxStopsAllowed
                            )
                            
                            ContinueButton(
                                title: "Continue",
                                isDisabled: shouldDisableNextButton,
                                action: nextStep
                            )
                        }
                    case 3:
                        if !isClosestStop {
                            VStack {
                                VariantSelectionStep(
                                    selectedStops: selectedStops,
                                    selectedVariants: $selectedVariants,
                                    maxVariantsPerStop: maxVariantsPerStop
                                )
                                
                                ContinueButton(
                                    title: "Continue",
                                    isDisabled: shouldDisableNextButton,
                                    action: nextStep
                                )
                            }
                        } else {
                            VStack {
                                NameConfigurationStep(
                                    widgetName: $widgetName,
                                    defaultName: generateDefaultWidgetName()
                                )
                                
                                ContinueButton(
                                    title: "Save",
                                    isDisabled: false,
                                    action: handleSave
                                )
                            }
                        }
                    case 4:
                        VStack {
                            NameConfigurationStep(
                                widgetName: $widgetName,
                                defaultName: generateDefaultWidgetName()
                            )
                            
                            ContinueButton(
                                title: "Save",
                                isDisabled: false,
                                action: handleSave
                            )
                        }
                    default:
                        EmptyView()
                    }
                }
                .offset(x: slideOffset)
                .opacity(opacity)
            }
            .navigationTitle("Widget Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if currentStep == 1 {
                        Button("Cancel") {
                            dismiss()
                        }
                    } else {
                        Button("Back") {
                            previousStep()
                        }
                    }
                }
            }
        }
        .alert("Cannot Save Widget", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage)
        }
    }
}



