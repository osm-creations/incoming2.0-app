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
                    let scenario = ProcessInfo.processInfo.environment["QA_CLIP_LINK"]
                    let path: String
                    switch scenario {
                    case "legacy": path = "/c/106/sample?t=local"
                    case "zero": path = "/c/BBBBBBBBBBBBBBBBBBBBBB"
                    case "meter": path = "/c/DDDDDDDDDDDDDDDDDDDDDD"
                    case "missing": path = "/c/CCCCCCCCCCCCCCCCCCCCCC"
                    default: path = "/c/AAAAAAAAAAAAAAAAAAAAAA"
                    }
                    let url = URL(string: "https://incoming2-0-server.incoming-osmcreations.workers.dev" + path)!
                    await coordinator.handle(url: url)
                }
        }
    }
}
