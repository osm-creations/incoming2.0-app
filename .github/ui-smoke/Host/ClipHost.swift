import SwiftUI

// UI-test host uses the shipping coordinator, models, network client and SwiftUI screens.
// It supplies only the invocation delivered by iOS when an App Clip is launched.
@main
struct ClipHost: App {
    @StateObject private var coordinator = ClipCoordinator()
    var body: some Scene {
        WindowGroup {
            ClipRootView()
                .environmentObject(coordinator)
                .preferredColorScheme(.dark)
                .task {
                    let profile = ProcessInfo.processInfo.environment["FIXTURE_PROFILE"] ?? "enabled"
                    let url = URL(string: "http://127.0.0.1:8743/c/fixture/\(profile)?t=local")!
                    await coordinator.handle(url: url)
                }
        }
    }
}
