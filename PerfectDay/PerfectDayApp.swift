//
//  PerfectDayApp.swift
//  PerfectDay
//
//  Created by James Whitford on 2024/06/05.
//

import SwiftUI

@main
struct PerfectDayApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
