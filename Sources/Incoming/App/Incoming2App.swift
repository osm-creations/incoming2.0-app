import SwiftUI

@main
struct Incoming2App: App {
    @StateObject private var session = AppSession()
    var body: some Scene {
        WindowGroup {
            Group {
                if session.isRestoring { ProgressView().tint(.white).frame(maxWidth: .infinity, maxHeight: .infinity).background(IncomingTheme.background) }
                else if session.isLoggedIn { DashboardView().id(session.user?.id) }
                else { LoginView() }
            }
            .environmentObject(session)
            .task { if session.isRestoring { await session.restore() } }
            .preferredColorScheme(.dark)
        }
    }
}
