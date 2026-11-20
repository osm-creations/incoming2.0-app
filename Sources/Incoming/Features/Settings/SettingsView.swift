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
                Text("In Settings → App Clip Settings, enter the force word or note, the caller name, and a reveal delay from 0 to 60 seconds. Tap Set & Save. To change the caller name from the dashboard, open Notes Input, edit the name, and save.")
                Text("In App Clip Settings, tap Copy Link or Write NFC Tag. Opening that link on the spectator’s iPhone starts the performance.")
                Text("To use the note as the caller name for this performance, tap Aa while editing in the App Clip. The call uses the first nonempty line, including later edits. Tap Aa again to return to the previous caller name. In plain Notes, use Tools → Use note as caller name.")
            }
            Section("Use Inject") {
                Text("In Settings, enter your Inject User ID and tap Save before starting the App Clip. To turn this off, clear the ID and save.")
                Text("In App Clip Notes, press and hold the checklist icon beside Aa to preview the latest Inject selection. The same checklist is available when the keyboard is closed. In plain Notes, tap Get caller name. Tap Use to choose the selection for this performance, or Close to keep the current caller name.")
            }
            Section("Reveal the call") {
                Text("Triple-tap the note to turn the screen black. Press either volume button once to start the saved delay. At maximum volume use Volume Down, and at minimum use Volume Up. A supported iPhone gives a haptic pulse for each step. Zero seconds reveals immediately. Slide to answer the simulated call or tap the plain name reveal to return to the note.")
            }
        }
        .navigationTitle("Performer Guide")
        .navigationBarTitleDisplayMode(.inline)
    }
}
