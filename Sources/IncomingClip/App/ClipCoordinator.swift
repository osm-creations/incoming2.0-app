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
    @Published private(set) var usesNoteAsCallerName = false
    private(set) var revealDelaySeconds = RevealDelay.defaultSeconds
    private var configuredName: String?
    private var selectedName: String?
    private var usesLegacyNoteName = false
    private var currentInvocation = UUID()
    private var lastStatusUpdate: Task<Void, Never>?

    func handle(url: URL) async {
        let requestId = UUID()
        currentInvocation = requestId
        lastStatusUpdate = nil
        revealDelaySeconds = RevealDelay.defaultSeconds
        configuredName = nil
        selectedName = nil
        usesNoteAsCallerName = false
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
                body: AnyEncodable(invocation)
            )
            guard currentInvocation == requestId else { return }
            revealDelaySeconds = RevealDelay.seconds(data.configuration.revealDelaySeconds)
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
        guard case .notes(_, let active) = state, active.id == session.id else {
            throw CancellationError()
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
        usesNoteAsCallerName = false
    }

    func setUsesNoteAsCallerName(_ enabled: Bool, session: ClipSession) {
        guard case .notes(_, let active) = state, active.id == session.id else { return }
        usesNoteAsCallerName = enabled
    }

    func enterBlack(text: String, session: ClipSession) {
        guard case .notes(_, let active) = state, active.id == session.id else { return }
        CallEffectsController.confirmCue()
        state = .black(text: text, session: session)
        reportStatus("BLACK_WAITING", session: session)
    }

    func returnToNote(text: String, session: ClipSession) {
        guard case .black(_, let active) = state, active.id == session.id else { return }
        CallEffectsController.confirmCue()
        state = .notes(text: text, session: session)
        reportStatus("NOTES", session: session)
    }

    func reveal(text: String, session: ClipSession) {
        guard case .black(_, let active) = state, active.id == session.id else { return }
        state = .call(text: text, session: session)
    }

    func finishCall(text: String, session: ClipSession) {
        guard case .call(_, let active) = state, active.id == session.id else { return }
        state = .notes(text: text, session: session)
        reportStatus("NOTES", session: session)
    }

    private func reportStatus(_ status: String, session: ClipSession) {
        // A quick return and re-entry must reach the server in the same order as the gestures.
        let previous = lastStatusUpdate
        lastStatusUpdate = Task {
            await previous?.value
            let _: StatusData? = try? await APIClient.shared.request(
                "/api/v1/app-clip/sessions/\(session.id)/status",
                method: "PATCH",
                body: AnyEncodable(ClipStatusRequest(status: status)),
                clipToken: session.token
            )
        }
    }

    func callerName(from text: String) -> String {
        if !usesNoteAsCallerName {
            if let selectedName { return selectedName }
            if let configuredName, !configuredName.isEmpty { return configuredName }
            if !usesLegacyNoteName { return "Unknown" }
        }
        return text.split(whereSeparator: \.isNewline)
            .lazy.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty }) ?? "Unknown"
    }
}

extension String {
    /// Uppercase word initials while preserving intentional casing such as McDonald or AJ.
    var callerDisplayName: String {
        var name = ""
        var atWordStart = true
        for character in self {
            if atWordStart && character.isLetter {
                name += character.uppercased()
            } else {
                name.append(character)
            }
            atWordStart = !character.isLetter && !character.isNumber
        }
        return name
    }
}

private struct StatusData: Decodable {
    let status: String
}
