import Vapor
import Foundation

public class Auth4sharedRouter: FederatedServiceRouter {
    public let tokens: FederatedServiceTokens
    public let callbackCompletion: (Request, String)throws -> (Future<ResponseEncodable>)
    public var scope: [String] = []
    public var callbackURL: String
    public let accessTokenURL: String = "https://api.4shared.com/v1_2/oauth/token"

    public required init(callback: String, completion: @escaping (Request, String)throws -> (Future<ResponseEncodable>)) throws {
        self.tokens = try Auth4sharedAuth()
        self.callbackURL = callback
        self.callbackCompletion = completion
    }

    public func obtainRequestToken(_ request: Request)throws -> Future<String> {
        return try request
        .client()
        .post("https://api.4shared.com/v1_2/oauth/initiate") { post in
            try post.query.encode(
                Auth4sharedInitiateBody(
                    oauth_consumer_key: tokens.clientID,
                    oauth_signature: tokens.clientSecret+"&"))
        }.flatMap { response in
            let session = try request.session()
            return try response.content.decode(Auth4sharedTokenResponse.self)
            .map { token in
                try session.set(Session.Keys.refresh,
                    to: Auth4sharedSignatureParam(
                        oauth_token: token.oauth_token,
                        oauth_consumer_key: self.tokens.clientID,
                        oauth_signature: self.tokens.clientSecret+"&"+token.oauth_token_secret))
                return token.oauth_token
            }
        }
    }

    public func authURL(_ request: Request)throws -> String {
        return "https://api.4shared.com/v1_2/oauth/authorize?oauth_callback=\(self.callbackURL)"
    }

    // Quasi-override, see Auth4shared.init for details
    public func configure4sharedRoutes(withAuthURL authURL: String, authenticateCallback: ((Request)throws -> (Future<Void>))?, on router: Router) throws {
        // Need to override to accommodate request token
        var callbackPath: String = callbackURL
        if try NSRegularExpression(pattern: "^https?:\\/\\/", options: []).matches(in: callbackURL, options: [], range: NSMakeRange(0, callbackURL.utf8.count)).count > 0 {
            callbackPath = URL(string: callbackPath)?.path ?? callbackURL
        }
        callbackPath = callbackPath != "/" ? callbackPath : callbackURL

        router.get(callbackPath, use: callback)
        router.get(authURL) { req -> Future<Response> in
            return try self.obtainRequestToken(req)
            .flatMap { token in
                let redirect: Response = req.redirect(to: try self.authURL(req)+"&oauth_token=\(token)")
                guard let authenticateCallback = authenticateCallback else {
                    return req.eventLoop.newSucceededFuture(result: redirect)
                }
                return try authenticateCallback(req).map(to: Response.self) { _ in
                    return redirect
                }
            }
        }
    }

    public func fetchToken(from request: Request)throws -> Future<String> {
        let code: String
        if let queryCode: String = try request.query.get(at: "oauth_token") {
            code = queryCode
        } else if let error: String = try request.query.get(at: "error") {
            throw Abort(.badRequest, reason: error)
        } else {
            throw Abort(.badRequest, reason: "Missing 'https://api.4shared.com/v1_2/oauth/authorize' key in URL query")
        }

        let session = try request.session()
        var signature = try session.get(Session.Keys.refresh, as: Auth4sharedSignatureParam.self)
        signature.oauth_token = code
        session[Session.Keys.refresh] = nil

        let body = Auth4sharedCallbackBody(signature: signature)
        return try request
        .client()
        .get(self.accessTokenURL) { request in
            try request.query.encode(body)
        }.flatMap { response in
            return try response.content.decode(Auth4sharedTokenResponse.self.self)
        }.map { token in
            return try String(data: JSONEncoder().encode(Auth4sharedSignatureParam(
                oauth_token: token.oauth_token,
                oauth_consumer_key: self.tokens.clientID,
                oauth_signature: self.tokens.clientSecret+"&"+token.oauth_token_secret)),
                              encoding: .utf8) ?? ""
        }
    }

    public func callback(_ request: Request)throws -> Future<Response> {
        return try self.fetchToken(from: request).flatMap(to: ResponseEncodable.self) { accessToken in
            let session = try request.session()

            session.setAccessToken(accessToken)
            try session.set("access_token_service", to: OAuthService.auth4shared)

            return try self.callbackCompletion(request, accessToken)
        }.flatMap(to: Response.self) { response in
            return try response.encode(for: request)
        }
    }
}
