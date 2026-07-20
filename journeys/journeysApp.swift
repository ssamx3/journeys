//
//  journeysApp.swift
//  journeys
//

import SwiftUI
import SwiftData

@main
struct journeysApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Journey.self, RailCompany.self, CommuterPass.self, Stamp.self])
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ContainerView(store: JourneyStore(context: modelContext))
    }
}
