import SwiftUI

@main
struct PerfectDayApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            TabView {
                JournalView()
                    .tabItem {
                        Label("Journal", systemImage: "book")
                    }

                MapView()
                    .tabItem {
                        Label("Map", systemImage: "map")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
