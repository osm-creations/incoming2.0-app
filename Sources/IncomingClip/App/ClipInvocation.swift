import Foundation

/// Bootstrap accepts either an opaque short tag or an already-issued signed link.
struct ClipInvocation: Encodable {
    let shortToken: String?
    let publicUserId: String?
    let publicConfigId: String?
    let capability: String?

    init?(url: URL) {
        let parts = url.pathComponents.filter { $0 != "/" }
        guard let index = parts.firstIndex(of: "c") else { return nil }
        let route = parts.dropFirst(index + 1)
        if route.count == 1, let token = route.first,
           token.utf8.count == 22, token.utf8.allSatisfy({ byte in
               (65...90).contains(byte) || (97...122).contains(byte) ||
               (48...57).contains(byte) || byte == 45 || byte == 95
           }) {
            shortToken = token
            publicUserId = nil
            publicConfigId = nil
            capability = nil
            return
        }
        guard route.count == 2,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let token = components.queryItems?.first(where: { $0.name == "t" })?.value,
              !token.isEmpty else { return nil }
        shortToken = nil
        publicUserId = route.first
        publicConfigId = route.last
        capability = token
    }
}
