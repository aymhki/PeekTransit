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
    @State private var showNoServiceAlert = false
    @State private var stopsWithoutService: [Int] = []
    @State private var noSelectedVariants: Bool = false
    @State private var multipleEntriesPerVariant: Bool = true
    @State private var selectedPerferredStopsInClosestStops = false
    @State private var isTransitioning = false
    let editingWidget: WidgetModel?

    
    
    init(editingWidget: WidgetModel? = nil) {
        self.editingWidget = editingWidget
        
        if let widget = editingWidget {
            _widgetSize = State(initialValue: widget.widgetData["size"] as? String ?? "medium")
            _selectedTimeFormat = State(initialValue: TimeFormat(rawValue: widget.widgetData["timeFormat"] as? String ?? "") ?? .default)
            _showLastUpdatedStatus = State(initialValue: widget.widgetData["showLastUpdatedStatus"] as? Bool ?? true)
            _isClosestStop = State(initialValue: widget.widgetData["isClosestStop"] as? Bool ?? false)
            _selectedStops = State(initialValue: widget.widgetData["stops"] as? [[String: Any]] ?? [])
            _widgetName = State(initialValue:widget.widgetData["name"] as? String ?? "")
            _noSelectedVariants = State(initialValue: widget.widgetData["noSelectedVariants"] as? Bool ?? false)
            _multipleEntriesPerVariant = State(initialValue: widget.widgetData["multipleEntriesPerVariant"] as? Bool ?? true)
            _selectedPerferredStopsInClosestStops = State(initialValue: widget.widgetData["selectedPerferredStopsInClosestStops"] as? Bool ?? false)
            
            var counter = 0
            
            if let stops = widget.widgetData["stops"] as? [[String: Any]] {
                var variants: [String: [[String: Any]]] = [:]
                for stop in stops {
                    if counter < getMaxStopsAllowedWith(widgetSizeGiven: widget.widgetData["size"] as? String ?? "medium") {
                        if let number = stop["number"] as? Int,
                           let selectedVariants = stop["selectedVariants"] as? [[String: Any]] {
                            variants[String(number)] = selectedVariants
                        }
                    }
                    
                    counter += 1
                }
                
                _selectedVariants = State(initialValue: variants)
            }
        }
    }

    private func generateDefaultWidgetName() -> String {
        
        
        if isClosestStop {
            return "Closest Stops \(selectedPerferredStopsInClosestStops ? "(With preferred stops)" : "") - \(widgetSize) - \(multipleEntriesPerVariant ? "Mixed Time Format" : selectedTimeFormat.formattedValue) - \(multipleEntriesPerVariant ? "Multiple enteries per variant" : "Single entry per variant") - \(showLastUpdatedStatus ? "Show Last Updated Status" : "Don't Show Last Updated Status")"
        } else {
            let stopNumbers = selectedStops.compactMap { stop -> String? in
                guard let number = stop["number"] as? Int else { return nil }
                return "#\(number)"
            }.joined(separator: ", ")
            
            var variantKeys = ""
            
            if (!noSelectedVariants) {
                variantKeys = selectedVariants.values.flatMap { variants in
                    variants.compactMap { $0["key"] as? String }
                }.joined(separator: ", ")
            } else {
                variantKeys = "Up Coming Buses"
            }
            
             return "\(stopNumbers) - \(variantKeys) - \(widgetSize) - \(multipleEntriesPerVariant ? "Mixed Time Format" : selectedTimeFormat.formattedValue) - \(multipleEntriesPerVariant ? "Multiple enteries per variant" : "Single entry per variant") - \(showLastUpdatedStatus ? "Show Last Updated Status" : "Don't Show Last Updated Status")"
            
            
        }
        
        
    }

    

    
    private func createWidgetData() -> [String: Any] {
        var widgetData: [String: Any] = [
            "size": widgetSize,
            "id":  UUID().uuidString,
            "createdAt": ISO8601DateFormatter().string(from: Date()),
            "isClosestStop": isClosestStop,
            "name": widgetName.isEmpty ? generateDefaultWidgetName() : widgetName,
            "timeFormat": selectedTimeFormat.formattedValue,
            "showLastUpdatedStatus": showLastUpdatedStatus,
            "noSelectedVariants": noSelectedVariants,
            "multipleEntriesPerVariant": multipleEntriesPerVariant,
            "selectedPerferredStopsInClosestStops": selectedPerferredStopsInClosestStops
        ]
        
        if isClosestStop {
            widgetData["type"] = "closest_stop"
        } else {

            widgetData["type"] = "multi_stop"
        }
        
        var stopsData: [[String: Any]] = []
        
        for stop in selectedStops {
            var stopData = stop
            if let stopNumber = stop["number"] as? Int,
               let variants = selectedVariants[String(stopNumber)] {
                stopData["selectedVariants"] = variants
            }
            stopsData.append(stopData)
        }
        
        widgetData[selectedPerferredStopsInClosestStops ? "perferredStops" : "stops"] = stopsData
        
        return widgetData
    }
    
    private func handleSave() {
        if widgetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            widgetName = generateDefaultWidgetName()
        }
        
        if let existingWidget = editingWidget {
            if SavedWidgetsManager.shared.hasWidgetWithName(widgetName) &&
               widgetName != existingWidget.widgetData["name"] as? String {
                saveErrorMessage = "A widget with this name already exists. Please choose a different name."
                showingSaveError = true
                return
            }
            
            SavedWidgetsManager.shared.updateWidget(existingWidget.id, with: createWidgetData())
        } else {
            if SavedWidgetsManager.shared.hasWidgetWithName(widgetName) {
                saveErrorMessage = "A widget with this name already exists. Please choose a different name."
                showingSaveError = true
                return
            }
            
            let widgetData = createWidgetData()
            let widget = WidgetModel(widgetData: widgetData)
            SavedWidgetsManager.shared.addWidget(widget)
        }
        dismiss()
    }
    
    private func animateStepTransition(forward: Bool, completion: @escaping () -> Void) {
        guard !isTransitioning else { return }
        
        isTransitioning = true
        let initialOffset = forward ? UIScreen.main.bounds.width : -UIScreen.main.bounds.width
        let animationOffset = forward ? -UIScreen.main.bounds.width : UIScreen.main.bounds.width
        
        slideOffset = initialOffset
        opacity = 0
        
        DispatchQueue.main.async {
            completion()
            
            withAnimation(.easeInOut(duration: 0.3)) {
                opacity = 1
                slideOffset = 0
            }
            
            // Reset transitioning state after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isTransitioning = false
            }
        }
    }
    
    private func nextStep() {
        animateStepTransition(forward: true) {
            if currentStep == 1 {
                if editingWidget != nil {
                    selectedStops = Array(selectedStops[0..<min(selectedStops.count, maxStopsAllowed)])
                } else {
                    selectedVariants = [:]
                }
            }
            
            if currentStep == 2 {
                if editingWidget != nil {
                    var newSelectedVariants = [String: [[String: Any]]]()
                    for (key, values) in selectedVariants {
                        newSelectedVariants[key] = Array(values.prefix(maxVariantsPerStop))
                    }
                    selectedVariants = newSelectedVariants
                }
            }
            
            currentStep += 1
        }
    }

    private func previousStep() {
        animateStepTransition(forward: false) {
            switch currentStep {
            case 3:
                if editingWidget == nil {
                    selectedVariants = [:]
                }
            case 2:
                if editingWidget == nil {
                    selectedStops = []
                    selectedVariants = [:]
                    isClosestStop = false
                    selectedPerferredStopsInClosestStops = false
                }
            default:
                break
            }
            
            currentStep -= 1
        }
    }
    
    private var shouldDisableNextButton: Bool {
        switch currentStep {
        case 1:
            return widgetSize.isEmpty
        case 2:
            return (selectedStops.isEmpty && !isClosestStop) || (selectedPerferredStopsInClosestStops && selectedStops.isEmpty)
        case 3:
            if isClosestStop && !selectedPerferredStopsInClosestStops {
                return false
            }
            return !selectedStops.allSatisfy { stop in
                guard let stopNumber = stop["number"] as? Int else { return false }
                return selectedVariants[String(stopNumber)]?.isEmpty == false
            } && !noSelectedVariants
        default:
            return false
        }
    }
    
    private var maxStopsAllowed: Int {
        if (multipleEntriesPerVariant) {
            return getMaxSopsAllowedForMultipleEntries(widgetSizeSystemFormat: nil, widgetSizeStringFormat: widgetSize)
        } else {
            return getMaxSopsAllowed(widgetSizeSystemFormat: nil, widgetSizeStringFormat: widgetSize)
        }
    }
    
    private func getMaxStopsAllowedWith(widgetSizeGiven: String) -> Int {
        if (multipleEntriesPerVariant) {
            return getMaxSopsAllowedForMultipleEntries(widgetSizeSystemFormat: nil, widgetSizeStringFormat: widgetSize)
        } else {
            return getMaxSopsAllowed(widgetSizeSystemFormat: nil, widgetSizeStringFormat: widgetSizeGiven)
        }
    }
    
    private var maxVariantsPerStop: Int {
        if (multipleEntriesPerVariant) {
            return getMaxVariantsAllowedForMultipleEntries(widgetSizeSystemFormat: nil, widgetSizeStringFormat: widgetSize)
        } else {
            return getMaxVariantsAllowed(widgetSizeSystemFormat: nil, widgetSizeStringFormat: widgetSize)
        }
        
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Group {
                    switch currentStep {
                    case 1:
                        VStack {
                            SizeSelectionStep(selectedSize: $widgetSize, selectedTimeFormat: $selectedTimeFormat, showLastUpdatedStatus: $showLastUpdatedStatus, multipleEntriesPerVariant: $multipleEntriesPerVariant)
                            
                            ContinueButton(
                                title: "Continue",
                                isDisabled: widgetSize.isEmpty || isTransitioning,
                                action: nextStep
                            )
                        }
                    case 2:
                        VStack {
                            StopSelectionStep(
                                selectedStops: $selectedStops,
                                isClosestStop: $isClosestStop,
                                selectedPerferredStopsInClosestStops: $selectedPerferredStopsInClosestStops,
                                maxStopsAllowed: maxStopsAllowed,
                                settingNotification: false
                            )
                            
                            ContinueButton(
                                title: "Continue",
                                isDisabled: shouldDisableNextButton || isTransitioning,
                                action: nextStep
                            )
                        }
                    case 3:
                        if !isClosestStop || selectedPerferredStopsInClosestStops {
                            VStack {
                                VariantSelectionStep(
                                    selectedStops: selectedStops,
                                    selectedVariants: $selectedVariants,
                                    maxVariantsPerStop: maxVariantsPerStop,
                                    settingNotification: false,
                                    stopsWithoutService: $stopsWithoutService,
                                    showNoServiceAlert: $showNoServiceAlert,
                                    noSelectedVariants: $noSelectedVariants
                                )
                                
                                ContinueButton(
                                    title: "Continue",
                                    isDisabled: shouldDisableNextButton || isTransitioning,
                                    action: nextStep
                                )
                            }
                        } else {
                            VStack {
                                NameConfigurationStep(
                                    widgetName: $widgetName,
                                    defaultName: generateDefaultWidgetName(),
                                    editingWidget: editingWidget != nil
                                )
                                
                                ContinueButton(
                                    title: "Save",
                                    isDisabled: false || isTransitioning,
                                    action: handleSave
                                )
                            }
                        }
                    case 4:
                        VStack {
                            NameConfigurationStep(
                                widgetName: $widgetName,
                                defaultName: generateDefaultWidgetName(),
                                editingWidget: editingWidget != nil
                            )
                            
                            ContinueButton(
                                title: "Save",
                                isDisabled: false  || isTransitioning,
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
                        .disabled(isTransitioning)
                    } else {
                        Button("Back") {
                            previousStep()
                        }
                        .disabled(isTransitioning)
                    }
                }
            }
        }
        .alert("Cannot Save Widget", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage)
        }
        .alert("Stop\(stopsWithoutService.count > 1 ? "s" : "") Without Service", isPresented: $showNoServiceAlert) {
            Button("Go Back", role: .cancel) {
                previousStep()
                selectedStops = []
            }
        } message: {
            Text("Stop\(stopsWithoutService.count > 1 ? "s" : "") \(stopsWithoutService.map { String($0) }.joined(separator: ", ")) doesn't have any active service. Please select different stops.")
        }
    }
}



