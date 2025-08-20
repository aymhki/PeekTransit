import SwiftUI
import Foundation
import CoreLocation

struct WidgetsView: View {
    @StateObject private var savedWidgetsManager = SavedWidgetsManager.shared
    @State private var showingSetupView = false
    @State private var selectedWidget: WidgetModel?
    @State private var isEditing = false
    @State private var selectedWidgets: Set<String> = []
    @State private var showingDeleteAlert = false
    @State private var widgetToDelete: WidgetModel? = nil
    @StateObject private var themeManager = ThemeManager.shared


    private var contentView: some View {
            Group {
                if savedWidgetsManager.isLoading {
                    ProgressView("Loading saved widgets...")
                } else if savedWidgetsManager.savedWidgets.isEmpty {

                    Text("No saved Widgets")
                        .foregroundColor(.secondary)

                    
                } else {
                    List {


                        ForEach(Array(savedWidgetsManager.savedWidgets.enumerated()), id: \.element.id) { index, savedWidget in

                            
                            WidgetRowView(
                                widgetData: savedWidget.widgetData,
                                onTap: {
                                    if isEditing {
                                        if selectedWidgets.contains(savedWidget.id) {
                                            selectedWidgets.remove(savedWidget.id)
                                        } else {
                                            selectedWidgets.insert(savedWidget.id)
                                        }
                                    } else {
                                        withAnimation {
                                            selectedWidget = savedWidget
                                           // showingSetupView = true
                                        }
                                    }
                                },
                                isEditing: isEditing,
                                isSelected: selectedWidgets.contains(savedWidget.id),
                                onDelete: {
                                    widgetToDelete = savedWidget
                                    showingDeleteAlert = true
                                }
                            )
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listSectionSeparator(.hidden)
//                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
//                                if !isEditing {
//                                    Button(role: .destructive) {
//                                        widgetToDelete = savedWidget
//                                        showingDeleteAlert = true
//                                    } label: {
//                                        Label("Delete", systemImage: "trash")
//                                    }
//                                }
//                            }
                            
                            if index < savedWidgetsManager.savedWidgets.count - 1 {
                                Divider()
                            }
                            
                        }
                    }
                    .listStyle(PlainListStyle())
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 100 : 80)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Widgets")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !savedWidgetsManager.savedWidgets.isEmpty {
                        Button(isEditing ? "Done" : "Select") {
                            withAnimation {
                                isEditing.toggle()
                                if !isEditing {
                                    selectedWidgets.removeAll()
                                }
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing && !selectedWidgets.isEmpty {
                        Button("Delete") {
                            showingDeleteAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .environmentObject(themeManager)
            .refreshable {
                savedWidgetsManager.loadSavedWidgets()
            }
            .alert("Confirm Deletion", isPresented: $showingDeleteAlert) {
                Button("No", role: .cancel) {
                    widgetToDelete = nil
                }
                Button("Yes", role: .destructive) {
                    withAnimation {
                        if let widget = widgetToDelete {
                            savedWidgetsManager.deleteWidget(for: widget.widgetData)
                            widgetToDelete = nil
                        } else {
                            for widgetId in selectedWidgets {
                                if let widget = savedWidgetsManager.savedWidgets.first(where: { $0.id == widgetId }) {
                                    savedWidgetsManager.deleteWidget(for: widget.widgetData)
                                }
                            }
                            selectedWidgets.removeAll()
                            isEditing = false
                        }
                    }
                }
            } message: {
                if let widget = widgetToDelete {
                    Text("Are you sure you want to delete \"\(widget.name)\"?")
                } else {
                    Text("Are you sure you want to delete \(selectedWidgets.count) widget\(selectedWidgets.count == 1 ? "" : "s")?")
                }
            }
    }
    
    var body: some View {

        if isLargeDevice() {
            NavigationStack {
                contentView
            }
            .overlay(alignment: .bottomTrailing) {
                if !isEditing {
                    Button {
                        selectedWidget = nil
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
            }
            .fullScreenCover(isPresented: $showingSetupView) {
                WidgetSetupView(editingWidget: selectedWidget)
            }
            .fullScreenCover(item: $selectedWidget) { widget in
                WidgetSetupView(editingWidget: widget)
            }
        } else {
            NavigationStack {
                contentView
            }
            .overlay(alignment: .bottomTrailing) {
                if !isEditing {
                    Button {
                        selectedWidget = nil
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
            }
            .fullScreenCover(isPresented: $showingSetupView) {
                WidgetSetupView(editingWidget: nil)
            }
            .fullScreenCover(item: $selectedWidget) { widget in
                WidgetSetupView(editingWidget: widget)
            }
        }
    }
    
}
