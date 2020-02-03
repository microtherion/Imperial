import Vapor

public class NextcloudAuth: FederatedServiceTokens {
    // Not used, provide a dummy implementation
    public static var idEnvKey: String = ""
    public static var secretEnvKey: String = ""
    public var clientID: String = ""
    public var clientSecret: String = ""
    
    public required init() throws {
    }
}
