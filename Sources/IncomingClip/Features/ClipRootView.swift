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
                    }
                )
                .id(session.id)

            case .black(let text, let session):
                BlackPerformanceView(ready: true) {
                    coordinator.reveal(text: text, session: session)
                }

            case .call(let text, let session):
                SimulatedCallView(caller: coordinator.callerName(from: text)) {
                    coordinator.finishCall(text: text, session: session)
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
