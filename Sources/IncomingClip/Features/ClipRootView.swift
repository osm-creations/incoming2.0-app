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

            case .menu(let config, let session):
                ClipMenuView(configuration: config, session: session)

            case .notes(let text, let session, let revision):
                NotesReplicaView(
                    initialText: text,
                    onTextChanged: { updatedText in
                        coordinator.updateCurrentText(updatedText, session: session, revision: revision)
                    },
                    onTripleTap: { updatedText in
                        coordinator.enterBlack(text: updatedText, session: session, revision: revision)
                    }
                )

            case .blackWaiting:
                BlackPerformanceView(ready: false, onTripleTap: {})

            case .blackReady(let text, let session, let revision, let injection):
                BlackPerformanceView(ready: true) {
                    coordinator.reveal(text: text, session: session, revision: revision, injection: injection)
                }

            case .call(let text, let session, let revision, let injection):
                SimulatedCallView(caller: injection.text) { result in
                    Task {
                        await coordinator.finishCall(result: result, text: text, session: session, revision: revision)
                    }
                }

            case .expired:
                MessageView(title: "Session Ended", message: "Scan the Incoming tag again to restart the experience.")

            case .error(let message):
                MessageView(title: "Unavailable", message: message)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: stateKey)
    }

    private var stateKey: String { String(describing: coordinator.state) }
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
