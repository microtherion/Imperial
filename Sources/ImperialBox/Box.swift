@_exported import ImperialCore
import Vapor

public struct Box: FederatedService {
    public var router: any FederatedServiceRouter

    public init(
        routes: some RoutesBuilder,
        authenticate: String,
        authenticateCallback: (@Sendable (Request) async throws -> Void)?,
        callback: String,
        scope: [String] = [],
        completion: @escaping @Sendable (Request, String) async throws -> some AsyncResponseEncodable
    ) throws {
        router = try BoxRouter(callback: callback, scope: scope, completion: completion)
        try router.configureRoutes(withAuthURL: authenticate, authenticateCallback: authenticateCallback, on: routes)
    }
}
