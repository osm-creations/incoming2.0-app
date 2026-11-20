import Foundation

enum APIClientError: LocalizedError {
    case invalidBaseURL
    case invalidResponse
    case server(status: Int, code: String?, message: String)
    case decoding

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL: "Invalid API base URL."
        case .invalidResponse: "Invalid server response."
        case .server(_, "INJECT_NOT_CONFIGURED", _): "Inject is off for this performer."
        case .server(_, "NO_SELECTION", _): "No caller name is available. Choose a value and try again."
        case .server(_, "SELECTION_UNAVAILABLE", _): "Could not load the Inject selection. Please try again."
        case .server(_, _, let message): message
        case .decoding: "Could not read the server response."
        }
    }
}

struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void
    init<T: Encodable>(_ value: T) { encodeClosure = value.encode }
    func encode(to encoder: Encoder) throws { try encodeClosure(encoder) }
}

final class APIClient {
    static let shared = APIClient()
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
    }

    private var baseURL: URL {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
              let url = URL(string: raw) else {
            return URL(string: "https://incoming2-0-server.incoming-osmcreations.workers.dev")!
        }
        return url
    }

    var passwordResetURL: URL {
        baseURL.appendingPathComponent("forgot-password")
    }

    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: AnyEncodable? = nil,
        bearer: String? = nil,
        clipToken: String? = nil
    ) async throws -> T {
        guard let url = URL(string: path, relativeTo: baseURL)?.absoluteURL else {
            throw APIClientError.invalidBaseURL
        }

        var request = URLRequest(url: url)
        if bearer != nil || clipToken != nil {
            request.cachePolicy = .reloadIgnoringLocalCacheData
        }
        request.httpMethod = method
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = try encoder.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if let bearer {
            request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        }

        if let clipToken {
            request.setValue("Clip \(clipToken)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        if !(200 ... 299).contains(http.statusCode) {
            let envelope = try? decoder.decode(APIErrorEnvelope.self, from: data)
            throw APIClientError.server(
                status: http.statusCode,
                code: envelope?.error.code,
                message: envelope?.error.message ?? "Request failed (\(http.statusCode))."
            )
        }

        do {
            return try decoder.decode(APIEnvelope<T>.self, from: data).data
        } catch {
            throw APIClientError.decoding
        }
    }
}
