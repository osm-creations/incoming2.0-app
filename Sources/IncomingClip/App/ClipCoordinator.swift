import Foundation
import SwiftUI

@MainActor
final class ClipCoordinator: ObservableObject {
    enum State {
        case awaitingInvocation
        case loading
        case notes(text: String, session: ClipSession)
        case black(text: String, session: ClipSession)
        case call(text: String, session: ClipSession)
        case expired
        case error(String)
    }

    @Published private(set) var state: State = .awaitingInvocation
    @Published private(set) var hasInjectUserId = false
    @Published private(set) var usesPlainPresentation = false
    private var configuredName: String?
    private var selectedName: String?
    private var usesLegacyNoteName = false
    private var currentInvocation = UUID()

    func handle(url: URL) async {
        let requestId = UUID()
        currentInvocation = requestId
        configuredName = nil
        selectedName = nil
        usesLegacyNoteName = false
        hasInjectUserId = false
        usesPlainPresentation = false
        guard let invocation = ClipInvocation(url: url) else {
            state = .error("This Incoming experience link is invalid.")
            return
        }

        state = .loading
        do {
            let data: ClipBootstrapData = try await APIClient.shared.request(
                "/api/v1/app-clip/bootstrap",
                method: "POST",
                body: AnyEncodable(ClipBootstrapRequest(
                    publicUserId: invocation.publicUserId,
                    publicConfigId: invocation.publicConfigId,
                    capability: invocation.capability
                ))
            )
            guard currentInvocation == requestId else { return }
            configuredName = data.configuration.callerName
            hasInjectUserId = data.configuration.hasInjectUserId == true
            usesPlainPresentation = data.configuration.usesPlainPresentation == true
            usesLegacyNoteName = data.configuration.hasInjectUserId == nil
            state = .notes(text: data.configuration.staticText ?? "", session: data.session)
        } catch APIClientError.server(let status, let code, _) where status == 401 || code == "SESSION_EXPIRED" {
            guard currentInvocation == requestId else { return }
            state = .expired
        } catch {
            guard currentInvocation == requestId else { return }
            state = .error(error.localizedDescription)
        }
    }

    func fetchSelection(session: ClipSession) async throws -> String {
        let response: InjectSelectionData
        do {
            response = try await APIClient.shared.request(
                "/api/v1/app-clip/sessions/\(session.id)/selection",
                clipToken: session.token
            )
        } catch let error as APIClientError {
            if case .server(_, let code, _) = error, code == "INJECT_NOT_CONFIGURED",
               case .notes(_, let active) = state, active.id == session.id {
                hasInjectUserId = false
            }
            throw error
        }
        let value = response.value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            throw APIClientError.server(status: 422, code: "NO_SELECTION", message: "No selection is available yet.")
        }
        return value
    }

    func useSelection(_ value: String, session: ClipSession) {
        guard case .notes(_, let active) = state, active.id == session.id else { return }
        selectedName = value
    }

    func useStandardPresentation(session: ClipSession) {
        guard case .notes(_, let active) = state, active.id == session.id else { return }
        usesPlainPresentation = false
    }

    func enterBlack(text: String, session: ClipSession) {
        guard case .notes(_, let active) = state, active.id == session.id else { return }
        state = .black(text: text, session: session)
        Task {
            let _: StatusData? = try? await APIClient.shared.request(
                "/api/v1/app-clip/sessions/\(session.id)/status",
                method: "PATCH",
                body: AnyEncodable(ClipStatusRequest(status: "BLACK_WAITING")),
                clipToken: session.token
            )
        }
    }

    func reveal(text: String, session: ClipSession) {
        guard case .black(_, let active) = state, active.id == session.id else { return }
        state = .call(text: text, session: session)
    }

    func finishCall(text: String, session: ClipSession) {
        guard case .call(_, let active) = state, active.id == session.id else { return }
        state = .notes(text: text, session: session)
    }

    func callerName(from text: String) -> String {
        if let selectedName { return selectedName }
        if let configuredName, !configuredName.isEmpty { return configuredName }
        if usesLegacyNoteName {
            return text.split(whereSeparator: \.isNewline)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first(where: { !$0.isEmpty }) ?? "Unknown"
        }
        return "Unknown"
    }
}

private struct StatusData: Decodable {
    let status: String
}
