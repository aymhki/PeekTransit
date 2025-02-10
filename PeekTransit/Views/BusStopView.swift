import SwiftUI
import MapKit


struct BusStopView: View {
    let stop: [String: Any]
    let isDeepLink: Bool
    @StateObject private var savedStopsManager = SavedStopsManager.shared
    @State private var isSaved: Bool = false
    @State private var schedules: [String] = []
    @State private var isLoading = true
    @State private var isManualRefresh = false
    @State private var errorFetchingSchedule = false
    @State private var errorText = ""
    @State private var isLiveUpdatesEnabled: Bool = false
    @State private var currentTheme: StopViewTheme = .default
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    @EnvironmentObject private var themeManager: ThemeManager

    
    private var liveUpdatesKey: String {
        "live_updates_\(stop["number"] as? Int ?? 0)"
    }
    
    private var coordinate: CLLocationCoordinate2D? {
        guard let centre = stop["centre"] as? [String: Any],
              let geographic = centre["geographic"] as? [String: Any],
              let lat = Double(geographic["latitude"] as? String ?? ""),
              let lon = Double(geographic["longitude"] as? String ?? "") else {
                    return nil
                }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    private func getLiveUpdatePreference() -> Bool {

        if UserDefaults.standard.object(forKey: liveUpdatesKey) != nil {
            return UserDefaults.standard.bool(forKey: liveUpdatesKey)
        }

        return true
    }
    
    private func loadSchedules(isManual: Bool) async {
        if isManual {
            isLoading = true
        }
        defer { isLoading = false }
        
        do {
            guard let stopNumber = stop["number"] as? Int else { return }
            let schedule = try await TransitAPI.shared.getStopSchedule(stopNumber: stopNumber)
            schedules = TransitAPI.shared.cleanStopSchedule(schedule: schedule, timeFormat: TimeFormat.minutesRemaining)
            errorFetchingSchedule = false
            errorText = ""
        } catch {
            print("Error loading schedules: \(error)")
            errorText = "Error loading schedules: \(error.localizedDescription)"
            errorFetchingSchedule = true
            isLiveUpdatesEnabled = false
        }
    }
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 30) {
                    HStack (spacing: 30) {
                        Text( (stop["name"] as? String ?? "Bus Stop"))
                            .font(.title3.bold())
                            .fixedSize(horizontal: false, vertical: true) 
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                            
                        
                        Spacer(minLength: 8)
                        
                        
                        LiveIndicator(isAnimating: isLiveUpdatesEnabled)
                            .padding()
                        
                    }
                    
                   
                    
                    Toggle("Live Updates", isOn: $isLiveUpdatesEnabled)
                    .onChange(of: isLiveUpdatesEnabled) { newValue in
                    UserDefaults.standard.set(newValue, forKey: liveUpdatesKey)
                        if newValue {
                            Task {
                                await loadSchedules(isManual: false)
                            }
                        }
                    }
                }
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
                    .padding()
                    
                    
                    
                    
                    
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
                            let components = schedule.components(separatedBy: getScheduleStringSeparator())
                            
 
                            if components.count > 1 {
                                GeometryReader { geometry in
                                    let totalWidth = geometry.size.width
                                    let spacing: CGFloat = 0

                                    let columnWidths = [
                                        // Route Key
                                        totalWidth * 0.13,
                                        
                                        // Route Name
                                        totalWidth * 0.44,
                                        
                                        // Arrival Status
                                        components[2].contains(getCancelledStatusTextString()) ? totalWidth * 0.36 :
                                        totalWidth * 0.16,
                                        
                                        // Arrival Time
                                        components[2].contains(getCancelledStatusTextString()) ? totalWidth * 0.0 :
                                            totalWidth * 0.24
                                    ]

                                    HStack(spacing: spacing) {
                                        Text(components[0])
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .frame(width: columnWidths[0], alignment: .leading)

                                        Text( components[1])
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .frame(width: columnWidths[1], alignment: .leading)


                                            Text(components[2])
                                                .lineLimit(nil)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .frame(width: columnWidths[2], alignment: .trailing)
                                                .stopViewTheme(themeManager.currentTheme, text: components[2])

                                        if (components.count > 3 && !components[2].contains(getCancelledStatusTextString())) {
                                            Text(components[3])
                                                .lineLimit(nil)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .frame(width: columnWidths[3], alignment: .trailing)
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 1)
                                }
                                .frame(height: 50)

                            }
                        }
                        .padding(.all)
                        Spacer()
                    }
                    .padding(.bottom, 50)
                    .stopViewTheme(themeManager.currentTheme, text: "")
                    //.clipShape(RoundedRectangle(cornerRadius: 12))
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .listRowInsets(EdgeInsets())
        }
        .listStyle(.plain)
        .navigationTitle("#\(String(stop["number"] as? Int ?? 0))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: isDeepLink ? .navigationBarLeading : .navigationBarTrailing) {
                Button {
                    savedStopsManager.toggleSavedStatus(for: stop)
                    isSaved.toggle()
                } label: {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
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
                    .bold()
                    .foregroundStyle(.white)
                    .padding()
                    .background(.blue)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding()
            .disabled(isLoading)
        }
        .modifier(ConditionalRefreshable(isEnabled: !isDeepLink) {
            isManualRefresh = true
            await loadSchedules(isManual: true)
        })
        .onAppear {
            isSaved = savedStopsManager.isStopSaved(stop)
            isLiveUpdatesEnabled = getLiveUpdatePreference()
            Task {
                await loadSchedules(isManual: false)
            }
            
            if let savedTheme = SharedDefaults.userDefaults?.string(forKey: settingsUserDefaultsKeys.sharedStopViewTheme),
               let theme = StopViewTheme(rawValue: savedTheme) {
                currentTheme = theme
            }
        }
        .onReceive(timer) { _ in
            guard isLiveUpdatesEnabled else { return }
            isManualRefresh = false
            Task {
                await loadSchedules(isManual: false)
            }
        }
    }
}

struct ConditionalRefreshable: ViewModifier {
    let isEnabled: Bool
    let action: () async -> Void

    func body(content: Content) -> some View {
        if isEnabled {
            content.refreshable {
                await action()
            }
        } else {
            content
        }
    }
}
