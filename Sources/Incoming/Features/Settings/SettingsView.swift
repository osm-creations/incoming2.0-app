import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var session: AppSession
    var body: some View {
        List {
            Section("Account") { LabeledContent("User ID", value: session.user?.publicUserId ?? "—"); LabeledContent("Email", value: session.user?.email ?? "—") }
            Section("App Clip") { NavigationLink("Edit App Clip Options") { ClipConfigListView() } }
            Section("Instructions") {
                Link("View User Guide", destination: URL(string:"https://incoming2-0-server.incoming-osmcreations.workers.dev/guide")!)
                Link("Video Tutorial", destination: URL(string:"https://incoming2-0-server.incoming-osmcreations.workers.dev/tutorial")!)
            }
            Section { Button("LOG OUT", role:.destructive) { Task { await session.logout() } }.frame(maxWidth:.infinity) }
        }.scrollContentBackground(.hidden).background(IncomingTheme.background).navigationTitle("Settings")
    }
}
