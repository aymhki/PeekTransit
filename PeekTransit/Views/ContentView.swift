import SwiftUI
import SwiftData
import WidgetKit
import StoreKit

struct ContentView: View {
    @State private var selection: Int = 0
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var deepLinkHandler = DeepLinkHandler.shared
    @StateObject private var tipBannerManager = TipBannerManager.shared
    @StateObject private var rateAppBannerManager = RateAppBannerManager.shared
    @AppStorage(settingsUserDefaultsKeys.defaultTab) private var defaultTab: Int = 0
    @State private var showUpdateAlert = false
    @State private var showStopView = false
    @State private var navigateToTipSupport = false
    @State private var selectedStop: Stop? = nil
    @State private var isLoadingStop = false
    @State private var loadingError: Error? = nil
    @State private var isSearchActive = false
    @Environment(\.requestReview) private var requestReview
    @State private var hasShownUpdateBannerThisSession = false
    @State private var isDetailViewPresentedOnMap = false

    
    private enum BannerType {
        case update, rate, tip
    }
    
    private var isBannerOnTop: Bool {
        return selection == 0 && !isDetailViewPresentedOnMap && !isLargeDevice()
    }

    private var activeBanner: BannerType? {
        if rateAppBannerManager.hasShownRateAppBannerThisSession || tipBannerManager.hasShownTipBannerThisSession || hasShownUpdateBannerThisSession {
            if rateAppBannerManager.hasShownRateAppBannerThisSession && rateAppBannerManager.shouldShowRateAppBanner { return .rate }
            if tipBannerManager.hasShownTipBannerThisSession && tipBannerManager.shouldShowTipBanner { return .tip }
            if hasShownUpdateBannerThisSession && showUpdateAlert { return .update }
            return nil
        }

        if showUpdateAlert { return .update }
        if rateAppBannerManager.shouldShowRateAppBanner { return .rate }
        if tipBannerManager.shouldShowTipBanner { return .tip }
        return nil
    }

    private var shouldShowBanner: Bool { activeBanner != nil }
    private var isUpdateBanner: Bool { activeBanner == .update }
    private var isRateAppBanner: Bool { activeBanner == .rate }
    private var isTipBanner: Bool { activeBanner == .tip }

    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                TabView(selection: $selection) {
                    MapView(
                        isSearchingActive: $isSearchActive,
                        isDetailViewPresented: $isDetailViewPresentedOnMap
                    )
                    .tabItem {
                        Label("Map", systemImage: "map.fill")
                    }
                    .tag(0)
                    
                    ListView()
                    .tabItem {
                        Label("Stops", systemImage: "list.bullet")
                    }
                    .tag(1)
                    
                    SavedStopsView()
                    .tabItem {
                        Label("Saved", systemImage: "bookmark.fill")
                    }
                    .tag(2)
                    
                    WidgetsView()
                    .tabItem {
                        Label("Widgets", systemImage: "note.text")
                    }
                    .tag(3)
                    
                    MoreTabView()
                    .tabItem {
                        Label("More", systemImage: "ellipsis.circle.fill")
                    }
                    .tag(4)
                }
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentTheme.preferredColorScheme)
                .safeAreaInset(edge: .top) {
                    if shouldShowBanner && selection == 0 && !isSearchActive && !isLargeDevice() && !isDetailViewPresentedOnMap {
                        bannerView(geometry: geometry)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    let showForMapDetail = (selection == 0 && isDetailViewPresentedOnMap)

                    if shouldShowBanner && ((selection != 0 || isLargeDevice()) || showForMapDetail) {
                        bannerView(geometry: geometry)
                    }
                }
                .onAppear {
                    if selection == 0 {
                        selection = defaultTab
                    }
                    
                    if (!rateAppBannerManager.hasAttemptedToStartTrackingRateAppBannerThisSession) {
                        rateAppBannerManager.startTrackingAppUsage()
                    }
                    
                    // if (!tipBannerManager.hasAttemptedToStartTrackingTipBannerThisSession) {
                        // tipBannerManager.startTrackingAppUsage()
                    // }
                    
                    NotificationCenter.default.addObserver(
                        forName: .appUpdateAvailable,
                        object: nil,
                        queue: .main
                    ) { _ in
                        showUpdateAlert = true
                    }
                    
                    Task {
                        await AppUpdateChecker().checkForUpdate()
                    }
                }
                .onDisappear {
                    tipBannerManager.stopTrackingAppUsage()
                    rateAppBannerManager.stopTrackingAppUsage()
                }
                .sheet(isPresented: $navigateToTipSupport) {
                    NavigationStack {
                        TipSupportView()
                            .navigationBarTitle("Support Development", displayMode: .inline)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button("Back") {
                                        navigateToTipSupport = false
                                    }
                                }
                            }
                        }
                }


                
                if isLoadingStop {
                    VStack {
                        ProgressView("Loading Stop...")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.4))
                    .zIndex(100)
                }
            }
        }
        .animation(.easeInOut, value: shouldShowBanner)
        .animation(.easeInOut, value: selection)
        .animation(.easeInOut, value: isDetailViewPresentedOnMap)
        .sheet(isPresented: $showStopView) {
            if let stop = selectedStop {
                NavigationStack {
                    BusStopView(stop: stop, isDeepLink: true, stopLoadError: loadingError)
                        .navigationBarItems(trailing: Button("Close") {
                            showStopView = false
                            loadingError = nil
                        })
                        .onAppear() {
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                }
            } else if loadingError != nil {
                StopLoadErrorView(error: loadingError, onRetry: {
                    handleDeepLink()
                }, onClose: {
                    showStopView = false
                    loadingError = nil
                })
            }
        }

        .onChange(of: deepLinkHandler.isShowingBusStop) { isShowing in
            if isShowing {
                handleDeepLink()
            }
        }
        .onChange(of: deepLinkHandler.selectedStopNumber) { newStopNumber in
            if showStopView && deepLinkHandler.isShowingBusStop {
                handleDeepLink()
            }
        }
    }
    
    @ViewBuilder
    private func bannerView(geometry: GeometryProxy) -> some View {
        let banner = activeBanner
        
        if (banner == nil) {
            EmptyView()
        } else {
            HStack(spacing: 8) {
                Image(systemName: banner == .update ? "arrow.down.circle.fill" : banner == .tip ? "heart.circle.fill" : banner == .rate ? "star.circle.fill" : "")
                            .foregroundColor(.white)
                            .font(.headline)
                Text(banner == .update ? "Update Available" : banner == .tip ? "Support Development"  : banner == .rate ? "Rate Peek Transit" : "")
                            .foregroundColor(.white)
                            .font(.headline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(banner == .update ? Color.accentColor : banner == .tip ?  Color.pink : banner == .rate ? Color.accentColor : Color.accentColor)
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, geometry.safeAreaInsets.bottom + 49)
            .transition(.move(edge: isBannerOnTop ? .top : .bottom).combined(with: .opacity))
            .onTapGesture {
                switch banner {
                    case .update:
                        hasShownUpdateBannerThisSession = true

                        if let appStoreURL = URL(string: "https://apps.apple.com/ca/app/peek-transit/id6741770809") {
                            UIApplication.shared.open(appStoreURL)
                            showUpdateAlert = false
                        }
                    case .tip:
                        tipBannerManager.tipBannerWasTapped()
                        navigateToTipSupport = true
                    case .rate:
                        rateAppBannerManager.rateAppBannerWasTapped()
                        requestReview()
                    case .none:
                        break
                }
            }
        }
    }
    
    private func handleDeepLink() {
        guard let stopNumber = deepLinkHandler.selectedStopNumber else {
            return
        }
        
        loadingError = nil
        
        if let currentStop = selectedStop,
           let currentStopNumber = currentStop.number as? Int,
           currentStopNumber == stopNumber {
            isLoadingStop = true
        } else {
            isLoadingStop = true
            selectedStop = nil
        }
        
        Task {
            do {
                if let stop = try await StopsDataStore.shared.getStop(number: stopNumber) {
                    DispatchQueue.main.async {
                        selectedStop = stop
                        showStopView = true
                        isLoadingStop = false
                    }
                } else {
                    DispatchQueue.main.async {
                        loadingError = TransitError.parseError("Stop not found")
                        showStopView = true
                        isLoadingStop = false
                    }
                }
            } catch {
                print("Error loading stop: \(error)")
                DispatchQueue.main.async {
                    loadingError = error
                    showStopView = true
                    isLoadingStop = false
                }
            }
            
            DispatchQueue.main.async {
                deepLinkHandler.isShowingBusStop = false
            }
        }
    }
}

