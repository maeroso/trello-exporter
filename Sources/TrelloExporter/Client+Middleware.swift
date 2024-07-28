import Foundation
import HTTPTypes
import OpenAPIRuntime
import OpenAPIURLSession

extension Client {
    static var authCredentials: (apiKey: String, apiToken: String)?

    enum TrelloAPIError: Error {
        case failedToDownloadContent(httpStatusCode: HTTPResponse.Status)
        case invalidContentURL
        case noCredentialsAvailable
    }

    struct AuthMiddleware: ClientMiddleware {
        let apiKey: String
        let apiToken: String

        func intercept(
            _ request: HTTPRequest,
            body: HTTPBody?,
            baseURL: URL,
            operationID: String,
            next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
        ) async throws -> (HTTPResponse, HTTPBody?) {
            var request = request
            request.path?.append("?key=\(apiKey)&token=\(apiToken)")
            return try await next(request, body, baseURL)
        }
    }

    init() throws {
        guard let authCredentials = Client.authCredentials else {
            throw TrelloAPIError.noCredentialsAvailable
        }
        self.init(
            serverURL: try Servers.server1(),
            configuration: .init(
                dateTranscoder: ISO8601DateTranscoder.iso8601WithFractionalSeconds),
            transport: URLSessionTransport(),
            middlewares: [AuthMiddleware(apiKey: authCredentials.apiKey, apiToken: authCredentials.apiToken)])
    }
}
