import Foundation

struct ClipInvocation {
    let publicUserId: String
    let publicConfigId: String
    let capability: String
    init?(url: URL) {
        let parts = url.pathComponents.filter { $0 != "/" }
        guard let cIndex = parts.firstIndex(of: "c"), parts.count > cIndex + 2,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let token = components.queryItems?.first(where: { $0.name == "t" })?.value,
              !token.isEmpty else { return nil }
        publicUserId = parts[cIndex + 1]
        publicConfigId = parts[cIndex + 2]
        capability = token
    }
}
