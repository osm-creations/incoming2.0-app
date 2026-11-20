import SwiftUI

@main
struct ClipHost: App {
    @StateObject private var coordinator = ClipCoordinator()
    var body: some Scene {
        WindowGroup {
            ClipRootView()
                .environmentObject(coordinator)
                .preferredColorScheme(.dark)
                .task {
                    let config = ProcessInfo.processInfo.environment["FIXTURE_PROFILE"] ?? "standard"
                    let url = URL(string: "http://127.0.0.1:8743/c/fixture/\(config)?t=local")!
                    await coordinator.handle(url: url)
                }
        }
    }
}
