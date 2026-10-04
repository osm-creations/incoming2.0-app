import SwiftUI

@main
struct IncomingClipApp: App {
    @StateObject private var coordinator = ClipCoordinator()
    var body: some Scene {
        WindowGroup {
            ClipRootView().environmentObject(coordinator).preferredColorScheme(.dark)
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in if let url=activity.webpageURL { Task { await coordinator.handle(url:url) } } }
                .onOpenURL { url in Task { await coordinator.handle(url:url) } }
        }
    }
}
