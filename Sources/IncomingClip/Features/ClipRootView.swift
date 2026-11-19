import SwiftUI

struct ClipRootView: View {
    @EnvironmentObject var coordinator: ClipCoordinator

    var body: some View {
        Group {
            switch coordinator.state {
            case .awaitingInvocation:
                LaunchPlaceholderView()

            case .loading:
                ProgressView("Opening Incoming…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)

            case .notes(let text, let session):
                NotesReplicaView(
                    initialText: text,
                    canFetchSelection: coordinator.hasInjectUserId,
                    fetchSelection: { try await coordinator.fetchSelection(session: session) },
                    onUseSelection: { coordinator.useSelection($0, session: session) },
                    onTripleTap: { updatedText in
                        coordinator.enterBlack(text: updatedText, session: session)
                    },
                    onUseStandardPresentation: coordinator.usesPlainPresentation
                        ? { coordinator.useStandardPresentation(session: session) } : nil
                )
                .id(session.id)

            case .black(let text, let session):
                BlackPerformanceView {
                    coordinator.reveal(text: text, session: session)
                }

            case .call(let text, let session):
                let caller = coordinator.callerName(from: text)
                if coordinator.usesPlainPresentation {
                    PlainNameReveal(caller: caller) {
                        coordinator.finishCall(text: text, session: session)
                    }
                } else {
                    SimulatedCallView(caller: caller) {
                        coordinator.finishCall(text: text, session: session)
                    }
                }

            case .expired:
                MessageView(
                    title: "Session Ended",
                    message: "Scan the Incoming tag again to restart the experience."
                )

            case .error(let message):
                MessageView(title: "Unavailable", message: message)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: stateKey)
    }

    private var stateKey: String {
        switch coordinator.state {
        case .awaitingInvocation: return "waiting"
        case .loading: return "loading"
        case .notes: return "notes"
        case .black: return "black"
        case .call: return "call"
        case .expired: return "expired"
        case .error: return "error"
        }
    }
}

@MainActor
private struct PlainNameReveal: View {
    let caller: String
    let onEnd: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var effects = CallEffectsController()

    var body: some View {
        Button {
            effects.stop()
            onEnd()
        } label: {
            Text(verbatim: caller)
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.white)
        .ignoresSafeArea()
        .accessibilityHint("Returns to the note")
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active { effects.start() } else { effects.stop() }
        }
        .onDisappear { effects.stop() }
    }
}

private struct LaunchPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "phone.down.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.blue)
                Text("Incoming")
                    .font(.largeTitle)
                Text("Open from your Incoming link or NFC tag.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

private struct MessageView: View {
    let title: String
    let message: String

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 10) {
                Text(title).font(.title2.bold())
                Text(message)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(30)
        }
    }
}
