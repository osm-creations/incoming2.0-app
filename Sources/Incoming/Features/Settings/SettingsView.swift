import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var session: AppSession

    var body: some View {
        List {
            Section("Account") {
                LabeledContent("User ID", value: session.user?.publicUserId ?? "—")
                LabeledContent("Email", value: session.user?.email ?? "—")
            }

            Section("App Clip") {
                NavigationLink("App Clip Settings") {
                    PrimaryClipSettingsView()
                }
            }

            Section {
                InjectInputView()
            } header: {
                Text("Inject User ID")
            } footer: {
                Text("Clear the ID and save to turn off Inject.")
            }

            Section("Instructions") {
                NavigationLink("Performer Guide") {
                    PerformerGuideView()
                }
            }

            Section {
                Button("LOG OUT", role: .destructive) {
                    Task { await session.logout() }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .scrollContentBackground(.hidden)
        .background(IncomingTheme.background)
        .navigationTitle("Settings")
    }
}

private struct PerformerGuideView: View {
    var body: some View {
        List {
            Section("Prepare the note and call") {
                Text("In Settings → App Clip Settings, enter the force word or note and the caller name. Tap Set & Save. To change the caller name from the dashboard, open Notes Input, edit the name, and save.")
                Text("In App Clip Settings, tap Copy Link or Write NFC Tag. Opening that link on the spectator’s iPhone starts the performance.")
            }
            Section("Use Inject") {
                Text("In Settings, enter your Inject User ID and tap Save before starting the App Clip. To turn this off, clear the ID and save.")
                Text("In App Clip Notes, long-press Share to preview the latest selection. Tap Use to make it the caller name for this performance, or Close to keep the current name.")
            }
            Section("Reveal the call") {
                Text("Triple-tap inside the note to show a black screen. Triple-tap the black screen again. The call appears five seconds later. Slide to answer. After Call Failed, the edited note returns.")
            }
        }
        .navigationTitle("Performer Guide")
        .navigationBarTitleDisplayMode(.inline)
    }
}
