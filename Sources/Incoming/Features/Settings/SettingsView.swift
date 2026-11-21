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
