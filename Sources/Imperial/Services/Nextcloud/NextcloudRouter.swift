import Vapor
import Foundation

public class NextcloudRouter: FederatedServiceRouter {
    public let tokens: FederatedServiceTokens
    public let callbackCompletion: (Request, String)throws -> (Future<ResponseEncodable>)
    public var scope: [String] = []
    public var callbackURL: String
    public let accessTokenURL: String = ""
    
    public required init(callback: String, completion: @escaping (Request, String)throws -> (Future<ResponseEncodable>)) throws {
        self.tokens = try NextcloudAuth()
        self.callbackURL = callback
        self.callbackCompletion = completion
    }

    public func configureRoutes(withAuthURL authURL: String, authenticateCallback: ((Request)throws -> (Future<Void>))?, on router: Router) throws {
        var callbackPath: String = callbackURL
        if try NSRegularExpression(pattern: "^https?:\\/\\/", options: []).matches(in: callbackURL, options: [], range: NSMakeRange(0, callbackURL.utf8.count)).count > 0 {
            callbackPath = URL(string: callbackPath)?.path ?? callbackURL
        }
        callbackPath = callbackPath != "/" ? callbackPath : callbackURL

        router.get(callbackPath, use: callback)
        router.get(callbackPath+"/poll", use: poll)
        router.get(authURL) { req -> Future<Response> in
            let redirect = try self.asyncAuthURL(req).map { url in
                req.redirect(to: url)
            }
            guard let authenticateCallback = authenticateCallback else {
                return redirect
            }
            return try authenticateCallback(req).flatMap(to: Response.self) { _ in
                return redirect
            }
        }
    }

    public func authURL(_ request: Request) throws -> String {
        fatalError("Nobody's supposed to call NextcloudRouter.authURL")
    }

    public func asyncAuthURL(_ request: Request) throws -> Future<String> {
        // Nextcloud has a rather odd login protocol
        guard var cloud = request.query[String.self, at: "cloud"] else { throw Abort(.badRequest) }

        if cloud.hasSuffix("/") {
            cloud.removeLast()
        }
        if cloud.range(of: "://") == nil {
            cloud = "https://"+cloud
        }
        let authURL = try authURLFrom(cloud).absoluteString
        let session = try request.session()
        session.setCloudDomain(cloud)
        struct AuthResponse : Decodable {
            struct Poll : Decodable {
                let token : String
                let endpoint : String
            }
            let poll    : Poll
            let login   : String
        }
        return try request.client().post(authURL) { request in
            let userAgent = ProcessInfo.processInfo.environment["NEXTCLOUD_USER_AGENT"] ?? "Imperial"
            request.http.headers.replaceOrAdd(name: .userAgent, value: userAgent )
        }.flatMap(to: AuthResponse.self) { response in
            guard response.http.status == .ok else {
                print(response)
                throw Abort(.internalServerError)
            }
            return try response.content.decode(AuthResponse.self)
        }.map { auth in
            try session.setNextcloudPollURL(auth.poll.endpoint)
            try session.setNextcloudPollToken(auth.poll.token)
            return auth.login
        }
    }

    public func fetchToken(from request: Request) throws -> Future<String> {
        let session = try request.session()
        struct Token : Encodable {
            let token: String
        }
        return try request.client().post(session.nextcloudPollURL()) { request throws in
            struct Token : Encodable {
                let token: String
            }
            let token = try Token(token: session.nextcloudPollToken())
            try request.content.encode(token, as: .urlEncodedForm)
        }.flatMap { response in
            return response.content.get(String.self, at: ["loginName"])
            .flatMap { userID in
                session.setNextcloudUserID(userID)
                return response.content.get(String.self, at: ["appPassword"])
            }
        }
    }

    public func poll(_ request: Request)throws -> Future<Response> {
        return try self.fetchToken(from: request).thenThrowing { accessToken in
            let session = try request.session()

            session.setAccessToken(accessToken)
            try session.set("access_token_service", to: OAuthService.nextcloud)
        }
        .transform(to: request.response())
    }

    public func callback(_ request: Request)throws -> Future<Response> {
        return try self.callbackCompletion(request, try request.session().accessToken())
        .flatMap(to: Response.self) { response in
            return try response.encode(for: request)
        }
    }

    private func authURLFrom(_ cloud: String) throws -> URL {
        return URL(string: "\(cloud)/index.php/login/v2")!
    }
}
