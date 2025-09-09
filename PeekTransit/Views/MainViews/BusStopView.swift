import SwiftUI
import MapKit

struct BusStopView: View {
    let stop: Stop
    let isDeepLink: Bool
    let stopLoadError: Error?
    
    @StateObject private var savedStopsManager = SavedStopsManager.shared
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var schedules: [ScheduleItem] = []
    @State private var isLoading = true
    @State private var isManualRefresh = false
    @State private var errorFetchingSchedule = false
    @State private var errorText = ""
    @State private var isLiveUpdatesEnabled: Bool = false
    @State private var userPreferredLiveUpdates: Bool = true
    @State private var currentTheme: StopViewTheme = .default
    @State private var stopNumber: Int = 0
    @State private var isFirstAppearance = true
    @State private var isSoftRefreshing = false

    
    let timer = Timer.publish(every: 59, on: .main, in: .common).autoconnect()
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
        
        defer {
            isLoading = false
            isSoftRefreshing = false
        }
        
        do {
            let schedule = try await TransitAPI.shared.getStopSchedule(stopNumber: stopNumber)
            let cleanedSchedules = TransitAPI.shared.cleanStopSchedule(schedule: schedule, timeFormat: TimeFormat.minutesRemaining)
            
            self.schedules = cleanedSchedules.map { scheduleString in
                        let components = scheduleString.components(separatedBy: getScheduleStringSeparator())
                        return ScheduleItem(components: components)
            }
            
            errorFetchingSchedule = false
            errorText = ""
            
            if userPreferredLiveUpdates {
                isLiveUpdatesEnabled = true
            }
        } catch {
            print("Error loading schedules: \(error)")
            self.schedules = []
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
                if isLoading && isManualRefresh {
                    VStack(spacing: 16) {
                        ProgressView()
                            .stopViewTheme(themeManager.currentTheme, text: "")
                            .tint(themeManager.currentTheme == .classic ? Color(hex: "#EB8634", brightness: 300, saturation: 50) : colorScheme == .dark ? .white : .black)
                        
                        Text("Loading schedules...")
                            .foregroundStyle(.secondary)
                            .stopViewTheme(themeManager.currentTheme, text: "")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .stopViewTheme(themeManager.currentTheme, text: "")
                    
                } else if errorFetchingSchedule {
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
                    .frame(maxWidth: .infinity)
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
                        ForEach(schedules) { scheduleItem in
                            if scheduleItem.components.count > 1 {
                                ScheduleRowView(
                                    components: scheduleItem.components,
                                    themeManager: themeManager
                                )
                                .stopViewTheme(themeManager.currentTheme, text: "")
                                .padding(.vertical, isLargeDevice() ? 16 : 15)
                            }
                        }
                        Spacer()
                    }
                    .opacity(isSoftRefreshing ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 0.5), value: isSoftRefreshing)
                    .padding(.bottom, 50)
                    .stopViewTheme(themeManager.currentTheme, text: "")
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .listRowBackground(
                themeManager.currentTheme == .classic ? Color.black : Color(.secondarySystemGroupedBackground)
            )
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
            
            if isFirstAppearance {
                isManualRefresh = true
                
                Task {
                    await loadSchedules(isManual: true)
                }
                
                isFirstAppearance = false
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
            isSoftRefreshing = true
            
            Task {
                await loadSchedules(isManual: false)
            }
        }
        .onChange(of: themeManager.currentTheme) { newTheme in
            currentTheme = newTheme
            isManualRefresh = true
            
            Task {
                await loadSchedules(isManual: true)
            }
        }
        .id(stopNumber)
    }
}

struct ScheduleRowView: View {
    let components: [String]
    let themeManager: ThemeManager
    
    private let columnWidthRatios: [CGFloat] = [0.15, 0.40, 0.20, 0.25]
    private let cancelledColumnWidthRatios: [CGFloat] = [0.15, 0.40, 0.45, 0.0]
    
    private var isCancelled: Bool {
        components.count > 2 && components[2].contains(getCancelledStatusTextString())
    }
    
    private var widthRatios: [CGFloat] {
        let baseRatios = isCancelled ? cancelledColumnWidthRatios : columnWidthRatios
        return adjustRatios(baseRatios, toSum: 1.0)
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            Color.clear
                .frame(height: 1)
                .onAppear {}
            
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Text(components[0])
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: geometry.size.width * widthRatios[0], alignment: .leading)
                        .stopViewTheme(themeManager.currentTheme, text: components[0])
                    
                    Text(components[1])
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: geometry.size.width * widthRatios[1], alignment: .leading)
                        .stopViewTheme(themeManager.currentTheme, text: components[1])
                    
                    Text(components[2])
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: geometry.size.width * widthRatios[2], alignment: isCancelled ? .center : .trailing)
                        .stopViewTheme(themeManager.currentTheme, text: components[2])
                        .padding(.trailing, 20)
                    
                    if components.count > 3 && !isCancelled {
                        Text(components[3])
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(width: geometry.size.width * widthRatios[3], alignment: .leading)
                            .stopViewTheme(themeManager.currentTheme, text: components[3])
                    }
                }
                .frame(height: getTextHeight())
            }
            .padding(.horizontal)
            .frame(height: getTextHeight())
        }
    }
    
    private func getTextHeight() -> CGFloat {
        return isLargeDevice() ? 50 : (components.count > 2 && components[1].count > 12) ? 35 : 20
    }
    
    private func adjustRatios(_ ratios: [CGFloat], toSum targetSum: CGFloat) -> [CGFloat] {
        let currentSum = ratios.reduce(0, +)
        guard currentSum > 0 else { return ratios }
        
        let scalingFactor = targetSum / currentSum
        return ratios.map { $0 * scalingFactor }
    }
    
}

struct ScheduleItem: Identifiable {
    let id = UUID()
    let components: [String]
}

