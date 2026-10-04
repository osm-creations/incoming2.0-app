import Foundation

enum ClipMode: String, Codable, CaseIterable, Identifiable {
    case menu = "MENU"
    case staticNote = "STATIC"
    case directNotes = "DIRECT_NOTES"
    var id: String { rawValue }
    var title: String {
        switch self { case .menu: "Menu Options"; case .staticNote: "Static Note"; case .directNotes: "Direct Notes" }
    }
}

struct ClipConfigSummary: Decodable, Identifiable {
    let id: String
    let publicConfigId: String
    let name: String
    let mode: ClipMode
    let enabled: Int
    let staticText: String?
    let openOverflowInitially: Int
    let capabilityVersion: Int
    let createdAt: String
    let updatedAt: String
    let invocationUrl: String
}

struct ClipConfigsData: Decodable { let configs: [ClipConfigSummary] }
struct ClipConfigCreateRequest: Encodable { let name: String; let mode: ClipMode; let staticText: String?; let openOverflowInitially: Bool; let enabled: Bool }
struct ClipConfigCreateData: Decodable { let config: ClipConfigRaw; let invocationUrl: String }
struct ClipConfigRaw: Decodable { let id: String; let publicConfigId: String; let name: String; let mode: ClipMode; let enabled: Int; let staticText: String?; let openOverflowInitially: Int }
struct ClipConfigDetailData: Decodable { let config: ClipConfigRaw; let options: [ClipOptionAdmin]; let invocationUrl: String }
struct ClipOptionAdmin: Decodable, Identifiable { let id: String; let value: String; let displayOrder: Int; let enabled: Int }

struct ClipConfigPatchRequest: Encodable {
    let name: String?
    let mode: ClipMode?
    let staticText: String?
    let openOverflowInitially: Bool?
    let enabled: Bool?
}
struct ClipOptionCreateRequest: Encodable { let value: String; let displayOrder: Int; let enabled: Bool }

struct ClipBootstrapRequest: Encodable { let publicUserId: String; let publicConfigId: String; let capability: String }
struct ClipBootstrapData: Decodable { let session: ClipSession; let configuration: SpectatorConfiguration }
struct ClipSession: Codable { let id: String; let token: String; let expiresAt: String }
struct SpectatorConfiguration: Decodable {
    let name: String
    let mode: ClipMode
    let staticText: String?
    let openOverflowInitially: Bool
    let options: [SpectatorOption]
}
struct SpectatorOption: Decodable, Identifiable { let id: String; let value: String }
struct ClipSelectionRequest: Encodable { let optionId: String }
struct ClipSelectionData: Decodable { let selectedValue: String }
struct ClipStatusRequest: Encodable { let status: String }
struct ClipStateData: Decodable { let revision: Int; let changed: Bool; let status: String; let payload: InjectionPayload? }
struct InjectionPayload: Decodable { let type: String; let text: String }
struct ConsumeRequest: Encodable { let result: String }
