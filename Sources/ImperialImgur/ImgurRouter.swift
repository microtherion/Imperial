import Vapor
import Foundation

public class ImgurRouter: FederatedServiceRouter {
    public let tokens: FederatedServiceTokens
    public let callbackCompletion: (Request, String)throws -> (EventLoopFuture<ResponseEncodable>)
    public var scope: [String] = []
    public var callbackURL: String
    public let accessTokenURL: String = "https://api.imgur.com/oauth2/token"
    
    public required init(callback: String, completion: @escaping (Request, String)throws -> (EventLoopFuture<ResponseEncodable>)) throws {
        self.tokens = try ImgurAuth()
        self.callbackURL = callback
        self.callbackCompletion = completion
    }

    public func authURL(_ request: Request) throws -> String {
        return "https://api.imgur.com/oauth2/authorize?" +
            "client_id=\(self.tokens.clientID)&" +
            "response_type=code"
    }
    
    public func fetchToken(from request: Request)throws -> EventLoopFuture<String> {
        let code: String
        if let queryCode: String = try request.query.get(at: "code") {
            code = queryCode
        } else if let error: String = try request.query.get(at: "error") {
            throw Abort(.badRequest, reason: error)
        } else {
            throw Abort(.badRequest, reason: "Missing 'code' key in URL query")
        }

        let body = ImgurCallbackBody(code: code, clientId: self.tokens.clientID, clientSecret: self.tokens.clientSecret)
        let url  = URI(string: self.accessTokenURL)
        return request.client.post(url) { client in
            try client.content.encode(body)
        }.flatMapThrowing { response in
            let refresh = try response.content.get(String.self, at: ["refresh_token"])
            try request.session.setRefreshToken(refresh)

            return try response.content.get(String.self, at: ["access_token"])
        }
    }
    
    public func callback(_ request: Request)throws -> EventLoopFuture<Response> {
        return try self.fetchToken(from: request).flatMap {
            accessToken -> EventLoopFuture<Response>
        in
            do {
                let session = request.session

                try session.setAccessToken(accessToken)
                try session.set("access_token_service", to: OAuthService.imgur)

                return try self.callbackCompletion(request, accessToken)
                .flatMap { response in
                    return response.encodeResponse(for: request)
                }
            } catch {
                return request.eventLoop.makeFailedFuture(error)
            }
        }
    }
}
