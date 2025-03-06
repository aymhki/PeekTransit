import SwiftUI

struct VariantSelectionStep: View {
    let selectedStops: [[String: Any]]
    @Binding var selectedVariants: [String: [[String: Any]]]
    let maxVariantsPerStop: Int
    @Binding var stopsWithoutService: [Int]
    @Binding var showNoServiceAlert: Bool
    @Binding var noSelectedVariants: Bool
    @State private var stopSchedules: [String: Set<UniqueVariant>] = [:]
    @State private var isLoading = false
    @State private var error: Error?
    

    
    struct UniqueVariant: Hashable {
        let key: String
        let name: String
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(key)
            hasher.combine(name)
        }
        
        static func == (lhs: UniqueVariant, rhs: UniqueVariant) -> Bool {
            return lhs.key == rhs.key && lhs.name == rhs.name
        }
    }
    
    private func processSchedules(_ schedules: [String]) -> Set<UniqueVariant> {
        var uniqueVariants = Set<UniqueVariant>()
        
        for schedule in schedules {
            let components = schedule.components(separatedBy: getScheduleStringSeparator())
            if components.count >= 2 {
                let variant = UniqueVariant(
                    key: components[0],
                    name: components[1]
                )
                uniqueVariants.insert(variant)
            }
        }
        
        return uniqueVariants
    }
    
    private func convertVariantArrayToUniqueSet(_ variants: [[String: Any]]) -> Set<UniqueVariant> {
        var uniqueVariants = Set<UniqueVariant>()
        
        for variantRouteObjects in variants {
            guard let variant = variantRouteObjects["variant"] as? [String: Any],
                  var key = variant["key"] as? String,
                  let name = variant["name"] as? String else { continue }
            
            
                    if let firstPart = key.split(separator: "-").first {
                        key = String(firstPart)
                    }
            
            
                    if (key.contains("BLUE")) {
                        key = "B"
                    }
            
                    uniqueVariants.insert(UniqueVariant(key: key, name: name))
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
                guard let stopNumber = stop["number"] as? Int else { continue }
                
                let schedule = try await TransitAPI.shared.getStopSchedule(stopNumber: stopNumber)
                let cleanSchedule =  TransitAPI.shared.cleanStopSchedule(schedule: schedule, timeFormat: .default)
                let stopVariants = try  await TransitAPI.shared.getOnlyVariantsForStop(stop: stop)
                let stopVaraintsSet = convertVariantArrayToUniqueSet(stopVariants)
                
                if (!cleanSchedule.isEmpty) {
                                        
                    await MainActor.run {
                        stopSchedules[String(stopNumber)] = stopVaraintsSet
                    }
                } else {
                    stopsNoService.append(stopNumber)
                    
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
    
    private func isVariantSelected(stopNumber: Int, variant: UniqueVariant) -> Bool {
        selectedVariants[String(stopNumber)]?.contains { selectedVariant in
            selectedVariant["key"] as? String == variant.key &&
            selectedVariant["name"] as? String == variant.name
        } ?? false
    }
    
    private func toggleVariantSelection(stopNumber: Int, variant: UniqueVariant) {
        let variantData: [String: Any] = [
            "key": variant.key,
            "name": variant.name
        ]
        
        let stopId = String(stopNumber)
        
        if var stopVariants = selectedVariants[stopId] {
            if let index = stopVariants.firstIndex(where: {
                ($0["key"] as? String) == variant.key &&
                ($0["name"] as? String) == variant.name
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
                ProgressView("Loading bus schedules...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = error {
                VStack(spacing: 8) {
                    Text("Error loading schedules")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task {
                            await loadSchedules()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Select the widget bus variants")
                            .font(.title3)
                            .padding([.top, .horizontal])
                    
                        
                        
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
                                    Text("Just show the next upcoming busees")
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
                        
                        
                        if !noSelectedVariants {
                            
                            ForEach(selectedStops.indices, id: \.self) { index in
                                let stop = selectedStops[index]
                                if let stopNumber = stop["number"] as? Int,
                                   let variants = stopSchedules[String(stopNumber)] {
                                    StopScheduleSection(
                                        stop: stop,
                                        variants: Array(variants),
                                        selectedVariants: selectedVariants[String(stopNumber)] ?? [],
                                        maxVariants: maxVariantsPerStop,
                                        onVariantSelect: { variant in
                                            withAnimation {
                                                toggleVariantSelection(stopNumber: stopNumber, variant: variant)
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
