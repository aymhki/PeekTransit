import SwiftUI

struct VariantSelectionStep: View {
    let selectedStops: [Stop]
    @Binding var selectedVariants: [String: [Variant]]
    let maxVariantsPerStop: Int
    let settingNotification: Bool
    @Binding var stopsWithoutService: [Int]
    @Binding var showNoServiceAlert: Bool
    @Binding var noSelectedVariants: Bool
    @State private var stopSchedules: [String: Set<Variant>] = [:]
    @State private var isLoading = false
    @State private var error: Error?
    
    
    private func processSchedules(_ schedules: [String]) -> Set<Variant> {
        var uniqueVariants = Set<Variant>()
        
        for schedule in schedules {
            let components = schedule.components(separatedBy: getScheduleStringSeparator())
            if components.count >= 2 {
                let variant = Variant(from: [
                    "key": components[0],
                    "name": components[1]
                ])
                uniqueVariants.insert(variant)
            }
        }
        
        return uniqueVariants
    }
    
    private func convertVariantArrayToUniqueSet(_ variants: [Variant]) -> Set<Variant> {
        var uniqueVariants = Set<Variant>()
        
        for variantRouteObjects in variants {
            var key = variantRouteObjects.key
            
    
    
            if let firstPart = key.split(separator: "-").first {
                key = String(firstPart)
            }
    
    
            if (key.contains("BLUE")) {
                key = "B"
            }
    
            uniqueVariants.insert(Variant(from: [
                "key": key,
                "name": variantRouteObjects.name
            ]))
        }
        
        return uniqueVariants
    }
    
    private func loadSchedules() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            var stopsNoService: [Int] = []
            
            for stop in selectedStops {
                guard stop.number != -1 else { continue }
                
                let schedule = try await TransitAPI.shared.getStopSchedule(stopNumber: stop.number)
                let cleanSchedule =  TransitAPI.shared.cleanStopSchedule(schedule: schedule, timeFormat: .default)
                let stopVariants = try  await TransitAPI.shared.getOnlyVariantsForStop(stop: stop)
                let stopVaraintsSet = convertVariantArrayToUniqueSet(stopVariants)
                
                if (!cleanSchedule.isEmpty) {
                                        
                    await MainActor.run {
                        stopSchedules[String(stop.number)] = stopVaraintsSet
                    }
                } else {
                    stopsNoService.append(stop.number)
                    
                    if !stopsNoService.isEmpty {
                        stopsWithoutService = stopsNoService
                        showNoServiceAlert = true
                    }
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                isLoading = false
            }
        }
    }
    
    private func isVariantSelected(stopNumber: Int, variant: Variant) -> Bool {
        selectedVariants[String(stopNumber)]?.contains { selectedVariant in
            selectedVariant.key  == variant.key &&
            selectedVariant.name == variant.name
        } ?? false
    }
    
    private func toggleVariantSelection(stopNumber: Int, variant: Variant) {
        let variantData: Variant = Variant(from:[
            "key": variant.key,
            "name": variant.name
        ])
        
        let stopId = String(stopNumber)
        
        if var stopVariants = selectedVariants[stopId] {
            if let index = stopVariants.firstIndex(where: {
                ($0.key) == variant.key &&
                ($0.name) == variant.name
            }) {
                stopVariants.remove(at: index)
                if stopVariants.isEmpty {
                    selectedVariants.removeValue(forKey: stopId)
                } else {
                    selectedVariants[stopId] = stopVariants
                }
            } else if stopVariants.count < maxVariantsPerStop {
                stopVariants.append(variantData)
                selectedVariants[stopId] = stopVariants
            }
        } else {
            selectedVariants[stopId] = [variantData]
        }
    }
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading bus stops schedules...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = error {
                VStack(spacing: 8) {
                    Text("Error loading schedules")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        self.error = nil
                        Task {
                            await loadSchedules()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        if settingNotification {
                            Text("Select the notification bus variant")
                                .font(.title3)
                                .padding([.top, .horizontal])
                        } else {
                            Text("Select the widget bus variants")
                                .font(.title3)
                                .padding([.top, .horizontal])
                        }
                    
                        if !settingNotification {
                            Button(action: {
                                withAnimation {
                                    noSelectedVariants.toggle()
                                    if noSelectedVariants {
                                        selectedVariants = [:]
                                    }
                                }
                            }) {
                                HStack(alignment: .center, spacing: 10) {
                                    Image(systemName: noSelectedVariants ? "checkmark.square.fill" : "square")
                                        .foregroundColor(noSelectedVariants ? .blue : .secondary)
                                        .font(.system(size: 28))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Automatically show the upcoming buses everytime")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        Text("No need to select specific variant(s)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                        }
                        
                        
                        if !noSelectedVariants || settingNotification {
                            
                            ForEach(Array(selectedStops.enumerated()), id: \.offset) { index, stop in
                                if let variants = stopSchedules[String(stop.number)] {
                                    StopScheduleSection(
                                        stop: stop,
                                        variants: Array(variants),
                                        selectedVariants: selectedVariants[String(stop.number)] ?? [],
                                        maxVariants: maxVariantsPerStop,
                                        onVariantSelect: { variant in
                                            withAnimation {
                                                toggleVariantSelection(stopNumber: stop.number, variant: variant)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            Task {
                await loadSchedules()
            }
        }

    }
}
