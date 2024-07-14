import SwiftUI

@main
struct BadmintonApp: App {
    @StateObject private var multipeerSession = MultipeerSession()

    var body: some Scene {
        WindowGroup {
            GameSetupView(multipeerSession: multipeerSession)
        }
    }
}
