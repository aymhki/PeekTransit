import SwiftUI

struct VariantSelectionStep: View {
    let selectedStops: [[String: Any]]
    @Binding var selectedVariants: [String: [[String: Any]]]
    let maxVariantsPerStop: Int
    
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
            let components = schedule.components(separatedBy: " ---- ")
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
    
    private func loadSchedules() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            for stop in selectedStops {
                guard let stopNumber = stop["number"] as? Int else { continue }
                
                let schedule = try await TransitAPI.shared.getStopSchedule(stopNumber: stopNumber)
                let cleanedSchedule = TransitAPI.shared.cleanStopSchedule(schedule: schedule, timeFormat: TimeFormat.minutesRemaining)
                let uniqueVariants = processSchedules(cleanedSchedule)
                
                await MainActor.run {
                    stopSchedules[String(stopNumber)] = uniqueVariants
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
                        Text("Select which bus variants you want to show on your widget")
                            .font(.title3)
                            .padding([.top, .horizontal])
                        
                        Text("You can select up to \(maxVariantsPerStop) variant\(maxVariantsPerStop > 1 ? "s" : "") per stop")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
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
