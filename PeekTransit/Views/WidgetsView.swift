import SwiftUI
import Foundation
import CoreLocation

struct WidgetsView: View {
    @StateObject private var savedWidgetsManager = SavedWidgetsManager.shared
    @State private var showingSetupView = false
    
    var body: some View {
        NavigationView {
            Group {
                if savedWidgetsManager.isLoading {
                    ProgressView("Loading saved widgets...")
                } else if savedWidgetsManager.savedWidgets.isEmpty {
                    Text("No saved Widgets")
                        .foregroundColor(.secondary)
                } else {
                    List {
                        ForEach(savedWidgetsManager.savedWidgets) { savedWidget in
                            WidgetRowView(widgetData: savedWidget.widgetData)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        savedWidgetsManager.deleteWidget(for: savedWidget.widgetData)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                showingSetupView = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.white)
                    .font(.title)
                    .foregroundStyle(.white)
                    .padding()
                    .background(.blue)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding()
        }
        .fullScreenCover(isPresented: $showingSetupView) {
            WidgetSetupView()
        }
        .refreshable {
            savedWidgetsManager.loadSavedWidgets()
        }
    }
}
