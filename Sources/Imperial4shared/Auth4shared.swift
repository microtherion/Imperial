@_exported import ImperialCore
import Vapor

public class Auth4shared: FederatedService {
    public var tokens: FederatedServiceTokens
    public var router: FederatedServiceRouter

    @discardableResult
    public required init(
        routes: RoutesBuilder,
        authenticate: String,
        authenticateCallback: ((Request)throws -> (EventLoopFuture<Void>))?,
        callback: String,
        scope: [String] = [],
        completion: @escaping (Request, String)throws -> (EventLoopFuture<ResponseEncodable>)
    ) throws {
        let myRouter = try Auth4sharedRouter(callback: callback, completion: completion)
        self.router  = myRouter
        self.tokens  = myRouter.tokens

        myRouter.scope = scope
        try myRouter.configureRoutes(withAuthURL: authenticate, authenticateCallback: authenticateCallback, on: routes)

        OAuthService.register(.auth4shared)
    }
}
