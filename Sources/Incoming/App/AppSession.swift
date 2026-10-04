import Foundation
import SwiftUI

@MainActor
final class AppSession: ObservableObject {
    @Published var user: UserAccount?
    @Published var isRestoring = true
    @Published var errorMessage: String?
    private(set) var accessToken: String?
    private let keychain = KeychainStore.shared

    var isLoggedIn: Bool { user != nil && accessToken != nil }

    func restore() async {
        defer { isRestoring = false }
        guard let refresh = keychain.read(account: "refresh_token") else { return }
        do {
            let data: RefreshData = try await APIClient.shared.request("/api/v1/auth/refresh", method: "POST", body: AnyEncodable(RefreshRequest(refreshToken: refresh)))
            accessToken = data.accessToken; user = data.user
            try keychain.save(data.refreshToken, account: "refresh_token")
        } catch { keychain.delete(account: "refresh_token") }
    }

    func login(login: String, password: String) async throws {
        let data: LoginData = try await APIClient.shared.request("/api/v1/auth/login", method: "POST", body: AnyEncodable(LoginRequest(login: login, password: password)))
        accessToken = data.accessToken; user = data.user
        try keychain.save(data.refreshToken, account: "refresh_token")
    }

    func logout() async {
        if let refresh = keychain.read(account: "refresh_token") {
            struct LogoutBody: Encodable { let refreshToken: String }
            let _: LogoutData? = try? await APIClient.shared.request("/api/v1/auth/logout", method: "POST", body: AnyEncodable(LogoutBody(refreshToken: refresh)))
        }
        keychain.delete(account: "refresh_token"); accessToken = nil; user = nil
    }

    func authenticated<T: Decodable>(_ path: String, method: String = "GET", body: AnyEncodable? = nil) async throws -> T {
        guard let token = accessToken else { throw APIClientError.server(status: 401, code: "UNAUTHENTICATED", message: "Please sign in again.") }
        do { return try await APIClient.shared.request(path, method: method, body: body, bearer: token) }
        catch APIClientError.server(let status, _, _) where status == 401 {
            guard let refresh = keychain.read(account: "refresh_token") else { throw APIClientError.server(status: 401, code: "UNAUTHENTICATED", message: "Please sign in again.") }
            let refreshed: RefreshData = try await APIClient.shared.request("/api/v1/auth/refresh", method: "POST", body: AnyEncodable(RefreshRequest(refreshToken: refresh)))
            accessToken = refreshed.accessToken; user = refreshed.user; try keychain.save(refreshed.refreshToken, account: "refresh_token")
            return try await APIClient.shared.request(path, method: method, body: body, bearer: refreshed.accessToken)
        }
    }
}
private struct LogoutData: Decodable { let loggedOut: Bool }
