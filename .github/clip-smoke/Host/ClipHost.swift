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
                    let legacy = ProcessInfo.processInfo.environment["QA_CLIP_LINK"] == "legacy"
                    let path = legacy ? "/c/105/sample?t=local" : "/c/AAAAAAAAAAAAAAAAAAAAAA"
                    let url = URL(string: "https://incoming2-0-server.incoming-osmcreations.workers.dev" + path)!
                    await coordinator.handle(url: url)
                }
        }
    }
}
