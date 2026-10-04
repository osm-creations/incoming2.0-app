import Foundation

struct APIEnvelope<T: Decodable>: Decodable { let data: T }
struct APIErrorEnvelope: Decodable { let error: APIErrorBody }
struct APIErrorBody: Decodable { let code: String; let message: String; let requestId: String? }

struct UserAccount: Codable, Identifiable {
    let id: String
    let publicUserId: String
    let email: String
    let role: String
    let status: String
}

struct LoginRequest: Encodable { let login: String; let password: String; let client = "ios" }
struct LoginData: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let user: UserAccount
    let forcePasswordChange: Bool
}
struct RefreshRequest: Encodable { let refreshToken: String }
struct RefreshData: Decodable { let accessToken: String; let refreshToken: String; let expiresIn: Int; let user: UserAccount }
