import Vapor
import Foundation

public class Auth4sharedRouter: FederatedServiceRouter {
    public let tokens: FederatedServiceTokens
    public let callbackCompletion: (Request, String)throws -> (EventLoopFuture<ResponseEncodable>)
    public var scope: [String] = []
    public var callbackURL: String
    public let accessTokenURL: String = "https://api.4shared.com/v1_2/oauth/token"

    public required init(callback: String, completion: @escaping (Request, String)throws -> (EventLoopFuture<ResponseEncodable>)) throws {
        self.tokens = try Auth4sharedAuth()
        self.callbackURL = callback
        self.callbackCompletion = completion
    }

    public func obtainRequestToken(_ request: Request)throws -> EventLoopFuture<String> {
        return request.client.post("https://api.4shared.com/v1_2/oauth/initiate") { post in
            try post.query.encode(
                Auth4sharedInitiateBody(
                    oauth_consumer_key: tokens.clientID,
                    oauth_signature: tokens.clientSecret+"&"))
        }.flatMapThrowing { response in
            let session = request.session
            let token   = try response.content.decode(Auth4sharedTokenResponse.self)

            try session.setRefreshToken(
                Auth4sharedSignatureParam(
                    oauth_token: token.oauth_token,
                    oauth_consumer_key: self.tokens.clientID,
                    oauth_signature: self.tokens.clientSecret+"&"+token.oauth_token_secret))
            return token.oauth_token
        }
    }

    public func authURL(_ request: Request)throws -> String {
        return "https://api.4shared.com/v1_2/oauth/authorize?oauth_callback=\(self.callbackURL)"
    }

    public func configureRoutes(withAuthURL authURL: String, authenticateCallback: ((Request)throws -> (EventLoopFuture<Void>))?, on router: RoutesBuilder) throws {
        // Need to override to accommodate request token
        var callbackPath: String = callbackURL
        if try NSRegularExpression(pattern: "^https?:\\/\\/", options: []).matches(in: callbackURL, options: [], range: NSMakeRange(0, callbackURL.utf8.count)).count > 0 {
            callbackPath = URL(string: callbackPath)?.path ?? callbackURL
        }
        callbackPath = callbackPath != "/" ? callbackPath : callbackURL

        router.get(callbackPath.pathComponents, use: callback)
        router.get(authURL.pathComponents) { req in
            return try self.obtainRequestToken(req)
            .flatMap { token -> EventLoopFuture<Response> in
                do {
                    let redirect = req.redirect(to: try self.authURL(req)+"&oauth_token=\(token)")
                    guard let authenticateCallback = authenticateCallback else {
                        return req.eventLoop.makeSucceededFuture(redirect)
                    }
                    return try authenticateCallback(req).map { _ in
                        return redirect
                    }
                } catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
            }
        }
    }

    public func fetchToken(from request: Request)throws -> EventLoopFuture<String> {
        let code: String
        if let queryCode: String = try request.query.get(at: "oauth_token") {
            code = queryCode
        } else if let error: String = try request.query.get(at: "error") {
            throw Abort(.badRequest, reason: error)
        } else {
            throw Abort(.badRequest, reason: "Missing 'oauth_token' key in URL query")
        }

        var signature = try request.session.get("refresh_token", as: Auth4sharedSignatureParam.self)
        signature.oauth_token = code
        request.session.data["refresh_token"] = nil

        let body = Auth4sharedCallbackBody(signature: signature)
        return request.client.get(URI(string: self.accessTokenURL)) { request in
            try request.query.encode(body)
        }.flatMapThrowing { response in
            return try response.content.decode(Auth4sharedTokenResponse.self.self)
        }.flatMapThrowing { token in
            return try String(data: JSONEncoder().encode(Auth4sharedSignatureParam(
                oauth_token: token.oauth_token,
                oauth_consumer_key: self.tokens.clientID,
                oauth_signature: self.tokens.clientSecret+"&"+token.oauth_token_secret)),
                              encoding: .utf8) ?? ""
        }
    }

    public func callback(_ request: Request)throws -> EventLoopFuture<Response> {
        return try self.fetchToken(from: request).flatMap {
            accessToken -> EventLoopFuture<ResponseEncodable>
        in
            do {
                try request.session.setAccessToken(accessToken)
                try request.session.set("access_token_service", to: OAuthService.auth4shared)

                return try self.callbackCompletion(request, accessToken)
            } catch {
                return request.eventLoop.makeFailedFuture(error)
            }
        }.flatMap { response in
            return response.encodeResponse(for: request)
        }
    }
}
