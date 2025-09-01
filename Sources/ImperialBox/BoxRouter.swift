import Vapor
import Foundation

struct BoxRouter: FederatedServiceRouter {
    let tokens: any FederatedServiceTokens
    let callbackCompletion: @Sendable (Request, String) async throws -> any AsyncResponseEncodable
    var scope: [String] = []
    var callbackURL: String
    let accessTokenURL: String = "https://api.box.com/oauth2/token"

    var callbackHeaders: HTTPHeaders {
        var headers = HTTPHeaders()
        headers.contentType = .urlEncodedForm
        return headers
    }

    init(callback: String, scope: [String], completion: @escaping @Sendable (Request, String) async throws -> some AsyncResponseEncodable) throws {
        self.tokens = try BoxAuth()
        self.callbackURL = callback
        self.callbackCompletion = completion
    }

    public func authURL(_ request: Request) throws -> String {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "account.box.com"
        components.path = "/api/oauth2/authorize"
        components.queryItems = [
            clientIDItem,
            redirectURIItem,
            scopeItem,
            codeResponseTypeItem,
        ]

        guard let url = components.url else {
            throw Abort(.internalServerError)
        }

        return url.absoluteString
    }

    func callbackBody(with code: String) -> any AsyncResponseEncodable {
        BoxCallbackBody(code: code, clientId: tokens.clientID, clientSecret: tokens.clientSecret)
    }
}
