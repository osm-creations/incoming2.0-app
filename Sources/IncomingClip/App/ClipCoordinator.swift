import Foundation
import SwiftUI

@MainActor
final class ClipCoordinator: ObservableObject {
    enum State {
        case awaitingInvocation
        case loading
        case menu(SpectatorConfiguration, ClipSession)
        case notes(text: String, session: ClipSession, revision: Int)
        case blackWaiting(text: String, session: ClipSession, revision: Int)
        case blackReady(text: String, session: ClipSession, revision: Int, injection: InjectionPayload)
        case call(text: String, session: ClipSession, revision: Int, injection: InjectionPayload)
        case expired
        case error(String)
    }

    @Published var state: State = .awaitingInvocation
    private var pollTask: Task<Void, Never>?

    deinit { pollTask?.cancel() }

    func handle(url: URL) async {
        guard let invocation = ClipInvocation(url: url) else {
            state = .error("This Incoming experience link is invalid.")
            return
        }

        state = .loading
        do {
            let data: ClipBootstrapData = try await APIClient.shared.request(
                "/api/v1/app-clip/bootstrap",
                method: "POST",
                body: AnyEncodable(
                    ClipBootstrapRequest(
                        publicUserId: invocation.publicUserId,
                        publicConfigId: invocation.publicConfigId,
                        capability: invocation.capability
                    )
                )
            )

            switch data.configuration.mode {
            case .menu:
                state = .menu(data.configuration, data.session)
            case .staticNote, .directNotes:
                state = .notes(text: data.configuration.staticText ?? "", session: data.session, revision: 0)
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func select(_ option: SpectatorOption, configuration: SpectatorConfiguration, session: ClipSession) async {
        do {
            let data: ClipSelectionData = try await APIClient.shared.request(
                "/api/v1/app-clip/sessions/\(session.id)/select",
                method: "POST",
                body: AnyEncodable(ClipSelectionRequest(optionId: option.id)),
                clipToken: session.token
            )
            state = .notes(text: data.selectedValue, session: session, revision: 0)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func updateCurrentText(_ text: String, session: ClipSession, revision: Int) {
        guard case .notes = state else { return }
        state = .notes(text: text, session: session, revision: revision)
    }

    func enterBlack(text: String, session: ClipSession, revision: Int) {
        state = .blackWaiting(text: text, session: session, revision: revision)
        Task {
            let _: StatusData? = try? await APIClient.shared.request(
                "/api/v1/app-clip/sessions/\(session.id)/status",
                method: "PATCH",
                body: AnyEncodable(ClipStatusRequest(status: "BLACK_WAITING")),
                clipToken: session.token
            )
        }
        startPolling(text: text, session: session, revision: revision)
    }

    private func startPolling(text: String, session: ClipSession, revision: Int) {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            var last = revision
            var failures = 0
            while !Task.isCancelled {
                do {
                    let data: ClipStateData = try await APIClient.shared.request(
                        "/api/v1/app-clip/sessions/\(session.id)/state?afterRevision=\(last)",
                        clipToken: session.token
                    )
                    failures = 0
                    if data.changed, let payload = data.payload {
                        last = data.revision
                        await MainActor.run {
                            self?.state = .blackReady(text: text, session: session, revision: last, injection: payload)
                        }
                        return
                    }
                } catch APIClientError.server(let status, let code, _) where status == 401 || code == "SESSION_EXPIRED" {
                    await MainActor.run { self?.state = .expired }
                    return
                } catch {
                    failures += 1
                }

                let delay = min(8.0, 2.5 + Double(failures))
                try? await Task.sleep(for: .seconds(delay))
            }
        }
    }

    func reveal(text: String, session: ClipSession, revision: Int, injection: InjectionPayload) {
        pollTask?.cancel()
        state = .call(text: text, session: session, revision: revision, injection: injection)
    }

    func finishCall(result: String, text: String, session: ClipSession, revision: Int) async {
        let _: ConsumedData? = try? await APIClient.shared.request(
            "/api/v1/app-clip/sessions/\(session.id)/consume",
            method: "POST",
            body: AnyEncodable(ConsumeRequest(result: result)),
            clipToken: session.token
        )
        state = .notes(text: text, session: session, revision: revision)
    }
}

private struct StatusData: Decodable { let status: String }
private struct ConsumedData: Decodable { let consumed: Bool }
