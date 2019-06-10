import Foundation
import Vapor

/// Defines a type that implements the routing to get an access token from an OAuth provider.
/// See implementations in the `Services/(Google|GitHub)/$0Router.swift` files
public protocol FederatedServiceRouter : class {
    
    /// A class that gets the client ID and secret from environment variables.
    var tokens: FederatedServiceTokens { get }
    
    /// The callback that is fired after the access token is fetched from the OAuth provider.
    /// The response that is returned from this callback is also returned from the callback route.
    var callbackCompletion: (Request, String)throws -> (Future<ResponseEncodable>) { get }
    
    /// The scopes to get permission for when getting the access token.
    /// Usage of this property varies by provider.
    var scope: [String] { get set }
    
    /// The URL (or URI) for that route that the provider will fire when the user authenticates with the OAuth provider.
    var callbackURL: String { get set }
    
    /// The URL on the app that will redirect to the `authURL` to get the access token from the OAuth provider.
    var accessTokenURL: String { get }
    
    /// The URL of the page that the user will be redirected to to get the access token.
    func authURL(_ request: Request) throws -> String
    
    /// Creates an instence of the type implementing the protocol.
    ///
    /// - Parameters:
    ///   - callback: The callback URL that the OAuth provider will redirect to after authenticating the user.
    ///   - completion: The completion handler that will be fired at the end of the `callback` route. The access token is passed into it.
    /// - Throws: Any errors that could occur in the implementation.
    init(callback: String, completion: @escaping (Request, String)throws -> (Future<ResponseEncodable>))throws
    
    
    /// Configures the `authenticate` and `callback` routes with the droplet.
    ///
    /// - Parameters:
    ///   - authURL: The URL for the route that will redirect the user to the OAuth provider.
    ///   - authenticateCallback: Execute custom code within the authenticate closure before redirection.
    /// - Throws: N/A
    func configureRoutes(withAuthURL authURL: String, authenticateCallback: ((Request)throws -> (Future<Void>))?, on router: Router)throws
    
    /// Gets an access token from an OAuth provider.
    /// This method is the main body of the `callback` handler.
    ///
    /// - Parameters: request: The request for the route
    ///   this method is called in.
    func fetchToken(from request: Request)throws -> Future<String>
    
    /// The route that the OAuth provider calls when the user has benn authenticated.
    ///
    /// - Parameter request: The request from the OAuth provider.
    /// - Returns: A response that should redirect the user back to the app.
    /// - Throws: An errors that occur in the implementation code.
    func callback(_ request: Request)throws -> Future<Response>
}

extension FederatedServiceRouter {
    public func configureRoutes(withAuthURL authURL: String, authenticateCallback: ((Request)throws -> (Future<Void>))?, on router: Router) throws {
        var callbackPath: String = callbackURL
        if try NSRegularExpression(pattern: "^https?:\\/\\/", options: []).matches(in: callbackURL, options: [], range: NSMakeRange(0, callbackURL.utf8.count)).count > 0 {
            callbackPath = URL(string: callbackPath)?.path ?? callbackURL
        }
        callbackPath = callbackPath != "/" ? callbackPath : callbackURL
        
        router.get(callbackPath, use: callback)
        router.get(authURL) { req -> Future<Response> in
            let redirect: Response = req.redirect(to: try self.authURL(req))
            guard let authenticateCallback = authenticateCallback else {
                return req.eventLoop.newSucceededFuture(result: redirect)
            }
            return try authenticateCallback(req).map(to: Response.self) { _ in
                return redirect
            }
        }
    }

    public func upgradeRelativeCallbackURL(from request: Request) {
        // If the OAuth provider needs an absolute callback URL and we have a relative URL,
        // concate it with the scheme and authority of the Referer of the request.
        if callbackURL.range(of: "://") == nil,
            let referer = request.http.headers.firstValue(name: .referer)
        {
            // Strip referer path if present
            if let path = referer.range(of: "/", range: String.Index(encodedOffset: 8)..<referer.endIndex) {
                callbackURL = String(referer[...path.lowerBound])+callbackURL
            } else {
                callbackURL = referer + callbackURL
            }
        }
    }
}
