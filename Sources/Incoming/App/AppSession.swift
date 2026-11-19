import Foundation
import SwiftUI

@MainActor
final class AppSession: ObservableObject {
    @Published var user: UserAccount?
    @Published var isRestoring = true
    private(set) var accessToken: String?
    private let keychain = KeychainStore.shared
    private var refreshing: Task<String, Error>?
    private var sessionGeneration = UUID()

    var isLoggedIn: Bool { user != nil && accessToken != nil }

    func restore() async {
        defer { isRestoring = false }
        guard keychain.read(account: "refresh_token") != nil else { return }
        _ = try? await refreshAccessToken()
    }

    func login(login: String, password: String) async throws {
        let data: LoginData = try await APIClient.shared.request(
            "/api/v1/auth/login", method: "POST",
            body: AnyEncodable(LoginRequest(login: login, password: password))
        )
        try keychain.save(data.refreshToken, account: "refresh_token")
        sessionGeneration = UUID()
        refreshing?.cancel()
        refreshing = nil
        accessToken = data.accessToken
        user = data.user
    }

    func logout() async {
        let refresh = keychain.read(account: "refresh_token")
        clearSession()
        if let refresh {
            let _: LogoutData? = try? await APIClient.shared.request(
                "/api/v1/auth/logout", method: "POST",
                body: AnyEncodable(RefreshRequest(refreshToken: refresh))
            )
        }
    }

    func authenticated<T: Decodable>(_ path: String, method: String = "GET", body: AnyEncodable? = nil) async throws -> T {
        let generation = sessionGeneration
        guard let token = accessToken else { throw signInRequired }
        do {
            return try await APIClient.shared.request(path, method: method, body: body, bearer: token)
        } catch APIClientError.server(let status, _, _) where status == 401 {
            guard sessionGeneration == generation, let current = accessToken else { throw signInRequired }
            let renewed = current == token ? try await refreshAccessToken() : current
            guard sessionGeneration == generation else { throw signInRequired }
            return try await APIClient.shared.request(path, method: method, body: body, bearer: renewed)
        }
    }

    private func refreshAccessToken() async throws -> String {
        if let refreshing { return try await refreshing.value }
        guard let refresh = keychain.read(account: "refresh_token") else {
            clearSession()
            throw signInRequired
        }

        let generation = sessionGeneration
        let task = Task<String, Error> {
            let data: RefreshData = try await APIClient.shared.request(
                "/api/v1/auth/refresh", method: "POST",
                body: AnyEncodable(RefreshRequest(refreshToken: refresh))
            )
            guard sessionGeneration == generation else { throw CancellationError() }
            try keychain.save(data.refreshToken, account: "refresh_token")
            accessToken = data.accessToken
            user = data.user
            return data.accessToken
        }
        refreshing = task
        defer { if generation == sessionGeneration { refreshing = nil } }
        do {
            return try await task.value
        } catch APIClientError.server(let status, _, _) where status == 401 {
            if generation == sessionGeneration { clearSession() }
            throw signInRequired
        }
    }

    private func clearSession() {
        sessionGeneration = UUID()
        refreshing?.cancel()
        refreshing = nil
        keychain.delete(account: "refresh_token")
        accessToken = nil
        user = nil
    }

    private var signInRequired: APIClientError {
        .server(status: 401, code: "UNAUTHENTICATED", message: "Please sign in again.")
    }
}

private struct LogoutData: Decodable { let loggedOut: Bool }
