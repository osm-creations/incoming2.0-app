import Foundation

struct PerformanceSessionsData: Decodable { let sessions: [PerformanceSession] }
struct PerformanceSession: Decodable, Identifiable {
    var id: String { publicSessionId }
    let publicSessionId: String
    let status: String
    let selectedValue: String?
    let latestRevision: Int
    let createdAt: String
    let expiresAt: String
    let lastSeenAt: String
    let configId: String
    let configName: String
    let mode: ClipMode
}
struct InjectRequest: Encodable { let value: String; let type = "INCOMING_CALL" }
struct InjectData: Decodable { let revision: Int; let status: String }
