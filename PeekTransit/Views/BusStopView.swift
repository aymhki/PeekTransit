import SwiftUI
import MapKit


struct BusStopView: View {
    let stop: [String: Any]
    @StateObject private var savedStopsManager = SavedStopsManager.shared
    @State private var isSaved: Bool = false
    @State private var schedules: [String] = []
    @State private var isLoading = true
    @State private var isManualRefresh = false
    @State private var errorFetchingSchedule = false
    @State private var errorText = ""
    let timer = Timer.publish(every: 20, on: .main, in: .common).autoconnect()
    
    private var coordinate: CLLocationCoordinate2D? {
        guard let centre = stop["centre"] as? [String: Any],
              let geographic = centre["geographic"] as? [String: Any],
              let lat = Double(geographic["latitude"] as? String ?? ""),
              let lon = Double(geographic["longitude"] as? String ?? "") else {
                    return nil
                }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    private func loadSchedules(isManual: Bool) async {
        if isManual {
            isLoading = true
        }
        defer { isLoading = false }
        
        do {
            guard let stopNumber = stop["number"] as? Int else { return }
            let schedule = try await TransitAPI.shared.getStopSchedule(stopNumber: stopNumber)
            schedules = TransitAPI.shared.cleanStopSchedule(schedule: schedule)
            errorFetchingSchedule = false
            errorText = ""
        } catch {
            print("Error loading schedules: \(error)")
            errorText = "Error loading schedules: \(error.localizedDescription)"
            errorFetchingSchedule = true
        }
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text(stop["name"] as? String ?? "Bus Stop")
                        .font(.title3.bold())
                    Spacer()
                    LiveIndicator()
                }
                .listRowBackground(Color.clear)
            }

            if let coordinate = coordinate {
                Section {
                    RealMapPreview(
                        coordinate: coordinate,
                        direction: stop["direction"] as? String ?? "Unknown Direction"
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .listRowInsets(EdgeInsets())
                }
            }
            
            Section {
                if isLoading && isManualRefresh {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading schedules...")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    
                } else if errorFetchingSchedule {
                    VStack(spacing: 16) {
                        Image(systemName: "bus.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text(errorText)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                } else if (schedules.isEmpty && !(isLoading || isManualRefresh)) {
                    VStack(spacing: 16) {
                        Image(systemName: "bus.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No service at this bus stop during this time.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else {
                    VStack(spacing: 0) {
                        Spacer()
                        ForEach(schedules, id: \.self) { schedule in
                            let components = schedule.components(separatedBy: " ---- ")
                            
 
                            if components.count > 1 {
                                GeometryReader { geometry in
                                    let totalWidth = geometry.size.width
                                    let spacing: CGFloat = 2
                                    let baseWidth = totalWidth * 0.14

                                    let columnWidths = [
                                        
                                        // Route Key
                                        baseWidth,
                                        
                                        // Route Name
                                        (components[2].contains("Late") || components[2].contains("Early") )  ? totalWidth * 0.36 :
                                        totalWidth * 0.56,
                                        
                                        // Arrival Status
                                        components[2].contains("Cancelled") ? totalWidth * 0.3 :
                                            (components[2].contains("Late") || components[2].contains("Early"))  ? totalWidth * 0.18 :
                                        totalWidth * 0.11,
                                        
                                        // Arrival Time
                                        components[2].contains("Cancelled") ? totalWidth * 0.0 :
                                            (components[2].contains("Late") || components[2].contains("Early"))  ? totalWidth * 0.3 :
                                            totalWidth * 0.3
                                    ]

                                    HStack(spacing: spacing) {
                                        Text(components[0])
                                            .font(.system(.subheadline, design: .monospaced).bold())
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .frame(width: columnWidths[0], alignment: .leading)

//                                        Text(components[1].count > 15 ? components[1].prefix(15) + "..." : components[1])
                                        Text(components[1])
//                                            .font(.system(size: 11, design: .monospaced).bold())
                                            .font(.system(.subheadline, design: .monospaced).bold())
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .frame(width: columnWidths[1], alignment: .leading)

                                        if ( components[2].contains("Late") || components[2].contains("Early") || components[2].contains("Cancelled") )  {
                                            Text(components[2])
                                                .font(.system(.headline, design: .monospaced).bold())
                                                .lineLimit(nil)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .frame(width: columnWidths[2], alignment: .leading)
                                                .foregroundStyle(
                                                    components[2].contains("Late") ? .red :
                                                        components[2].contains("Cancelled") ? .red :
                                                        components[2].contains("Early") ? .yellow :
                                                            .primary
                                                )
                                        }

                                        if (components.count > 3 && !components[2].contains("Cancelled")) {
                                            Text(components[3])
                                                .font(.system(.headline, design: .monospaced).bold())
                                                .lineLimit(nil)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .frame(width: columnWidths[3], alignment: .leading)
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 8)
                                }
                                .frame(height: 50)

                            }
                        }
                        .padding(.all)
                        Spacer()
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("#\(String(stop["number"] as? Int ?? 0))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    savedStopsManager.toggleSavedStatus(for: stop)
                    isSaved.toggle()
                } label: {
                    Image(systemName: isSaved ? "star.fill" : "star")
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                isManualRefresh = true
                Task {
                    await loadSchedules(isManual: true)
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding()
                    .background(.blue)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding()
        }
        .refreshable {
            isManualRefresh = true
            await loadSchedules(isManual: true)
        }
        .onAppear {
            isSaved = savedStopsManager.isStopSaved(stop)
            Task {
                await loadSchedules(isManual: false)
            }
        }
        .onReceive(timer) { _ in
            isManualRefresh = false
            Task {
                await loadSchedules(isManual: false)
            }
        }
    }
}
