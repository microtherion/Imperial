import Vapor

public class Auth4shared: FederatedService {
    public var tokens: FederatedServiceTokens
    public var router: FederatedServiceRouter

    @discardableResult
    public required init(
        router: Router,
        authenticate: String,
        authenticateCallback: ((Request)throws -> (Future<Void>))?,
        callback: String,
        scope: [String] = [],
        completion: @escaping (Request, String)throws -> (Future<ResponseEncodable>)
    ) throws {
        // configureRoutes is defined in an extension of FederatedServiceRouter, so we cannot override
        // We dispatch to the static type instead to achieve the same effect.
        let myRouter = try Auth4sharedRouter(callback: callback, completion: completion)
        self.router  = myRouter
        self.tokens  = myRouter.tokens

        myRouter.scope = scope
        try myRouter.configure4sharedRoutes(withAuthURL: authenticate, authenticateCallback: authenticateCallback, on: router)

        OAuthService.register(.auth4shared)
    }
}
