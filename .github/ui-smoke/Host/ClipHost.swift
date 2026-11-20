import SwiftUI

// Presents the same production views, coordinators and network client as the shipping targets.
// Invocation and login here use only data on the simulator runner's local HTTP fixture.
@main
struct ClipHost: App {
    @StateObject private var coordinator = ClipCoordinator()
    @StateObject private var session = AppSession()
    @State private var loginError: String?
    private let profile = ProcessInfo.processInfo.environment["FIXTURE_PROFILE"] ?? "enabled"

    var body: some Scene {
        WindowGroup {
            if profile == "performer" {
                Group {
                    if session.isLoggedIn {
                        NavigationStack { InjectInputView().environmentObject(session) }
                    } else if let loginError {
                        Text(loginError)
                    } else {
                        ProgressView().task {
                            do { try await session.login(login: "fixture", password: "fixture") }
                            catch { loginError = error.localizedDescription }
                        }
                    }
                }
                .preferredColorScheme(.dark)
            } else {
                ClipRootView()
                    .environmentObject(coordinator)
                    .preferredColorScheme(.dark)
                    .task {
                        let url = URL(string: "http://127.0.0.1:8743/c/fixture/\(profile)?t=local")!
                        await coordinator.handle(url: url)
                    }
            }
        }
    }
}
