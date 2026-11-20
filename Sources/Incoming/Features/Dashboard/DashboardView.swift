import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var session: AppSession
    @State private var clearMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                IncomingTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            IncomingLogo(size: 92)

                            Text("Incoming")
                                .font(.system(size: 36, weight: .medium))
                                .accessibilityAddTraits(.isHeader)

                            Text("By OSM Creations")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 20)

                        NavigationLink {
                            NotesInputView()
                        } label: {
                            DashboardTile(icon: "doc.text.fill", title: "NOTES INPUT")
                        }

                        HStack(spacing: 14) {
                            Button {
                                Task { await clearSavedText() }
                            } label: {
                                Label("CLEAR", systemImage: "sparkles")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(IncomingButtonStyle(prominent: false))

                            NavigationLink {
                                SettingsView()
                            } label: {
                                Label("SETTINGS", systemImage: "gearshape.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(IncomingButtonStyle(prominent: false))
                        }

                        if let clearMessage {
                            Text(clearMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(22)
                    .frame(maxWidth: 620)
                }
            }
            .navigationBarHidden(true)
        }
        .tint(IncomingTheme.accent)
    }

    private func clearSavedText() async {
        do {
            let _: PrimaryClipData = try await session.authenticated(
                "/api/v1/clip-configs/primary",
                method: "PATCH",
                body: AnyEncodable(PrimaryClipUpdateRequest(staticText: "", callerName: ""))
            )
            clearMessage = "Force word and caller name cleared."
        } catch {
            clearMessage = error.localizedDescription
        }
    }
}

private struct DashboardTile: View {
    let icon: String
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 34))
                .foregroundStyle(IncomingTheme.accent)

            Text(title)
                .font(.title3)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(IncomingTheme.card.opacity(0.75))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(IncomingTheme.border.opacity(0.65), lineWidth: 1)
        )
    }
}
