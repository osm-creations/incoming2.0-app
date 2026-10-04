import SwiftUI

struct InjectInputView: View {
    @EnvironmentObject var session: AppSession

    @State private var sessions: [PerformanceSession] = []
    @State private var selectedId = ""
    @State private var value = ""
    @State private var message: String?
    @State private var busy = false

    var body: some View {
        Form {
            Section("Active App Clip session") {
                if sessions.isEmpty {
                    Text("No active spectator session.")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Session", selection: $selectedId) {
                        ForEach(sessions) { performanceSession in
                            Text("\(performanceSession.configName) • \(performanceSession.status)")
                                .tag(performanceSession.publicSessionId)
                        }
                    }
                }
            }

            Section("Injection") {
                TextField("Caller / reveal text", text: $value)
                    .textInputAutocapitalization(.words)

                Button("Send Injection") {
                    Task { await send() }
                }
                .disabled(
                    selectedId.isEmpty ||
                    value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    busy
                )
            }

            if let message {
                Section {
                    Text(message)
                        .foregroundStyle(message.hasPrefix("Sent") ? .green : .red)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(IncomingTheme.background)
        .navigationTitle("Inject Input")
        .task { await load() }
    }

    private func load() async {
        let data: PerformanceSessionsData? = try? await session.authenticated(
            "/api/v1/performance/sessions"
        )

        sessions = data?.sessions ?? []

        if selectedId.isEmpty {
            selectedId = sessions.first?.publicSessionId ?? ""
        }
    }

    private func send() async {
        busy = true
        defer { busy = false }

        do {
            let _: InjectData = try await session.authenticated(
                "/api/v1/performance/sessions/\(selectedId)/inject",
                method: "POST",
                body: AnyEncodable(InjectRequest(value: value))
            )
            message = "Sent. App Clip can now reveal on the next triple tap."
        } catch {
            message = error.localizedDescription
        }
    }
}

struct ClearInjectionView: View {
    @EnvironmentObject var session: AppSession

    @State private var sessions: [PerformanceSession] = []
    @State private var selected = ""
    @State private var message = ""

    var body: some View {
        Form {
            Section("Session") {
                if sessions.isEmpty {
                    Text("No active sessions")
                } else {
                    Picker("Session", selection: $selected) {
                        ForEach(sessions) { performanceSession in
                            Text(performanceSession.configName)
                                .tag(performanceSession.publicSessionId)
                        }
                    }
                }
            }

            Section {
                Button("Clear Pending Injection", role: .destructive) {
                    Task { await clear() }
                }
                .disabled(selected.isEmpty)

                if !message.isEmpty {
                    Text(message)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(IncomingTheme.background)
        .navigationTitle("Clear")
        .task { await load() }
    }

    private func load() async {
        let data: PerformanceSessionsData? = try? await session.authenticated(
            "/api/v1/performance/sessions"
        )
        sessions = data?.sessions ?? []
        selected = sessions.first?.publicSessionId ?? ""
    }

    private func clear() async {
        do {
            let _: SimpleCleared = try await session.authenticated(
                "/api/v1/performance/sessions/\(selected)/injection",
                method: "DELETE"
            )
            message = "Cleared."
        } catch {
            message = error.localizedDescription
        }
    }
}

private struct SimpleCleared: Decodable {
    let cleared: Bool
}
