import SwiftUI

struct StopSelectionStep: View {
    @Binding var selectedStops: [[String: Any]]
    @Binding var isClosestStop: Bool
    let maxStopsAllowed: Int
    
    @StateObject private var locationManager = LocationManager()
    @State private var stops: [[String: Any]] = []
    @State private var isLoading = false
    @State private var error: Error?
    
    private func loadNearbyStops() async {
        guard let location = locationManager.location else { return }
        
        isLoading = true
        error = nil
        
        do {
            let nearbyStops = try await TransitAPI.shared.getNearbyStops(userLocation: location)
            let enrichedStops = try await TransitAPI.shared.getVariantsForStops(stops: nearbyStops)
            
            await MainActor.run {
                self.stops = enrichedStops
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    private func toggleStopSelection(_ stop: [String: Any]) {
        if let index = selectedStops.firstIndex(where: { ($0["number"] as? Int) == (stop["number"] as? Int) }) {
            selectedStops.remove(at: index)
        } else if selectedStops.count < maxStopsAllowed {
            selectedStops.append(stop)
        }
    }
    
    private func isStopSelected(_ stop: [String: Any]) -> Bool {
        selectedStops.contains(where: { ($0["number"] as? Int) == (stop["number"] as? Int) })
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("You can select up to \(maxStopsAllowed) stop\(maxStopsAllowed > 1 ? "s" : "") for this widget size")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
            
            Button(action: {
                withAnimation {
                    isClosestStop.toggle()
                    if isClosestStop {
                        selectedStops = []
                    }
                }
            }) {
                HStack {
                    if isClosestStop {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                        Text("Closest Stop(s) based on loaction selected, click again to go back or click next to proceed")
                    } else {
                        Image(systemName: "location.fill")
                        Text("Use Closest Stop based on my location at the time of viewing the widget")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isClosestStop ? Color.red : Color.accentColor)
                .foregroundColor(isClosestStop ? .white : Color(uiColor: UIColor.systemBackground))
                .cornerRadius(10)
            }
            .padding(.horizontal)
            
            if !isClosestStop {
                HStack {
                    Text("Selected stops: \(selectedStops.count)/\(maxStopsAllowed)")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                
                if isLoading {
                    ProgressView("Loading nearby stops...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = error {
                    VStack(spacing: 8) {
                        Text("Error loading stops")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            Task {
                                await loadNearbyStops()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(stops.indices, id: \.self) { index in
                            let stop = stops[index]
                            if let variants = stop["variants"] as? [[String: Any]] {
                                SelectableStopRow(
                                    stop: stop,
                                    variants: variants,
                                    isSelected: isStopSelected(stop),
                                    onSelect: {
                                        withAnimation {
                                            toggleStopSelection(stop)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .onAppear {
            locationManager.requestLocation()
        }
        .onChange(of: locationManager.location) { newLocation in
            if let location = newLocation {
                Task {
                    await loadNearbyStops()
                }
            }
        }
    }
}
