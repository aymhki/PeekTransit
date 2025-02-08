import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selection: Int = 0

    var body: some View {
        TabView(selection: $selection) {
            MapView()
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
            
        }
    }
}

#Preview {
    ContentView()
}


