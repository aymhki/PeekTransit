import SwiftUI
import MapKit

struct BusStopView: View {
    let stop: Stop
    let isDeepLink: Bool
    let stopLoadError: Error?
    
    @StateObject private var savedStopsManager = SavedStopsManager.shared
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var schedules: [String] = []
    @State private var isLoading = true
    @State private var isManualRefresh = false
    @State private var errorFetchingSchedule = false
    @State private var errorText = ""
    @State private var isLiveUpdatesEnabled: Bool = false
    @State private var userPreferredLiveUpdates: Bool = true
    @State private var currentTheme: StopViewTheme = .default
    @State private var stopNumber: Int = 0
    
    let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    @State private var isRefreshCooldown = false
    @State private var isAppActive = true
    private let cooldownDuration: TimeInterval = 1.0
    
    private var isRefreshDisabled: Bool {
        isLoading || isRefreshCooldown
    }
    
    private var isSaved: Bool {
        savedStopsManager.isStopSaved(stop)
    }
    
    private var liveUpdatesKey: String {
        "live_updates_\(stopNumber)"
    }
    
    private var coordinate: CLLocationCoordinate2D? {
        return CLLocationCoordinate2D(latitude: stop.centre.geographic.latitude, longitude: stop.centre.geographic.longitude)
    }
    
    init(stop: Stop, isDeepLink: Bool, stopLoadError: Error? = nil) {
        self.stop = stop
        self.isDeepLink = isDeepLink
        self.stopLoadError = stopLoadError
        self._stopNumber = State(initialValue: stop.number)
    }
    
    private func getLiveUpdatePreference() -> Bool {
        if UserDefaults.standard.object(forKey: liveUpdatesKey) != nil {
            return UserDefaults.standard.bool(forKey: liveUpdatesKey)
        }
        return true
    }
    
    private func loadSchedules(isManual: Bool) async {
        guard isAppActive else { return }
        if isManual {
            isLoading = true
            isRefreshCooldown = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + cooldownDuration) {
                isRefreshCooldown = false
            }
        }
        
        defer { isLoading = false }
        
        do {
            let schedule = try await TransitAPI.shared.getStopSchedule(stopNumber: stopNumber)
            schedules = TransitAPI.shared.cleanStopSchedule(schedule: schedule, timeFormat: TimeFormat.minutesRemaining)
            errorFetchingSchedule = false
            errorText = ""
            
            if userPreferredLiveUpdates {
                isLiveUpdatesEnabled = true
            }
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
                    HStack(spacing: 30) {
                        Text((stop.name))
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
                            if !errorFetchingSchedule {
                                UserDefaults.standard.set(newValue, forKey: liveUpdatesKey)
                                userPreferredLiveUpdates = newValue
                            }
                            
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
                        direction: stop.direction
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .listRowInsets(EdgeInsets())
                }
            }
            
            Section {
                if isLoading && isManualRefresh  {
                    VStack(spacing: 16) {
                        ProgressView()
                            .stopViewTheme(themeManager.currentTheme, text: "")
                            .tint(themeManager.currentTheme == .classic ? Color(hex: "#EB8634", brightness: 300, saturation: 50) : colorScheme == .dark ? .white : .black)
                        
                        Text("Loading schedules...")
                            .foregroundStyle(.secondary)
                            .stopViewTheme(themeManager.currentTheme, text: "")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding([.vertical, .horizontal])
                    .stopViewTheme(themeManager.currentTheme, text: "")
                    
                } else if errorFetchingSchedule && isAppActive {
                    VStack(spacing: 16) {
                        Image(systemName: getGlobalBusIconSystemImageName())
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text(errorText)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        
                        Button(action: {
                            isManualRefresh = true
                            Task {
                                await loadSchedules(isManual: true)
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Retry")
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                    .padding([.vertical, .horizontal])
                    
                } else if schedules.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: getGlobalBusIconSystemImageName())
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No service at this bus stop during this time.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding([.vertical, .horizontal])
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
                                        totalWidth * 0.13,
                                        totalWidth * 0.42,
                                        components[2].contains(getCancelledStatusTextString()) ? totalWidth * 0.36 : totalWidth * 0.23,
                                        components[2].contains(getCancelledStatusTextString()) ? totalWidth * 0.0 : totalWidth * 0.25
                                    ]
                                    
                                    HStack(spacing: spacing) {
                                        Text(components[0])
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .frame(width: columnWidths[0], alignment: .leading)
                                        
                                        Text(components[1])
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .frame(width: columnWidths[1], alignment: .leading)
                                        
                                        
                                        Text(components[2])
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .frame(width: columnWidths[2], alignment: .trailing)
                                            .stopViewTheme(themeManager.currentTheme, text: components[2])
                                            .padding(.trailing, 20)
                                        
                                    
                                        if components.count > 3 && !components[2].contains(getCancelledStatusTextString()) {
                                            Text(components[3])
                                                .lineLimit(nil)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .frame(width: columnWidths[3], alignment: .leading)
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 1)
                                }
                                .frame(height: isLargeDevice() ? 50 : 25)
                            }
                        }
                        .padding(.all)
                        Spacer()
                    }
                    .padding(.bottom, 50)
                    .stopViewTheme(themeManager.currentTheme, text: "")
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 0)
        .environment(\.defaultMinListHeaderHeight, 0)
        .listSectionSeparator(.hidden)
        .navigationTitle("#\(String(stopNumber))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: isDeepLink ? .navigationBarLeading : .navigationBarTrailing) {
                Button {
                    savedStopsManager.toggleSavedStatus(for: stop)
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
                    .background(isRefreshDisabled ? Color.gray : .blue)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding()
            .disabled(isRefreshDisabled)
            .animation(.easeInOut, value: isRefreshDisabled)
        }
        .modifier(ConditionalRefreshable(isEnabled: !isDeepLink) {
            guard !isRefreshCooldown else { return }
            isManualRefresh = true
            await loadSchedules(isManual: true)
        })
        .onAppear {
            if stop.number != -1 {
                stopNumber = stop.number
            }
            
            networkMonitor.startMonitoring()
            userPreferredLiveUpdates = getLiveUpdatePreference()
            isLiveUpdatesEnabled = userPreferredLiveUpdates
            isManualRefresh = true
            Task {
                await loadSchedules(isManual: true)
            }
            
            if let savedTheme = SharedDefaults.userDefaults?.string(forKey: settingsUserDefaultsKeys.sharedStopViewTheme),
               let theme = StopViewTheme(rawValue: savedTheme) {
                currentTheme = theme
            }
        }
        .onDisappear {
            networkMonitor.stopMonitoring()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            isAppActive = false
            
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            isAppActive = true
        }
        .onReceive(timer) { _ in
            guard isAppActive && isLiveUpdatesEnabled else { return }
            isManualRefresh = false
            
            Task {
                await loadSchedules(isManual: false)
            }
        }
        .id(stopNumber)
    }
}
