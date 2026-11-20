import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var session: AppSession
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var clearMessage: String?

    var body: some View {
        NavigationStack {
            GeometryReader { viewport in
                ScrollView {
                    VStack(spacing: 24) {
                        header
                        actions
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 22)
                    .padding(.vertical, verticalSizeClass == .compact ? 12 : 22)
                    .frame(maxWidth: 620)
                    .frame(maxWidth: .infinity, minHeight: viewport.size.height)
                }
            }
            .background(IncomingTheme.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .tint(IncomingTheme.accent)
    }

    private var header: some View {
        VStack(spacing: 8) {
            IncomingLogo(size: verticalSizeClass == .compact ? 58 : 92)

            Text("Incoming 2.0")
                .font(.largeTitle.weight(.medium))
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("dashboard.title")

            Text("By OSM Creations")
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
    }

    private var actions: some View {
        VStack(spacing: 14) {
            if let clearMessage {
                Text(clearMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            NavigationLink {
                NotesInputView()
            } label: {
                DashboardTile(minimumHeight: verticalSizeClass == .compact ? 88 : 150)
            }
            .accessibilityIdentifier("dashboard.notes")

            let row = typeSize >= .xxxLarge
                ? AnyLayout(VStackLayout(spacing: 14))
                : AnyLayout(HStackLayout(spacing: 14))
            row {
                Button {
                    Task { await clearSavedText() }
                } label: {
                    Label("CLEAR", systemImage: "sparkles")
                }
                .accessibilityIdentifier("dashboard.clear")

                NavigationLink {
                    SettingsView()
                } label: {
                    Label("SETTINGS", systemImage: "gearshape.fill")
                }
                .accessibilityIdentifier("dashboard.settings")
            }
            .buttonStyle(IncomingButtonStyle(prominent: false))
        }
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
    let minimumHeight: CGFloat

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 34))
                .foregroundStyle(IncomingTheme.accent)

            Text("NOTES INPUT")
                .font(.title3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: minimumHeight)
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
