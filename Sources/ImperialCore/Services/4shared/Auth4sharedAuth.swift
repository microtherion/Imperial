import Vapor

// 4shared clients don't need registration
public class Auth4sharedAuth: FederatedServiceTokens {
    public static var idEnvKey: String = "AUTH4SHARED_CLIENT_ID"
    public static var secretEnvKey: String = "AUTH4SHARED_CLIENT_SECRET"
    public var clientID: String = ""
    public var clientSecret: String = ""

    public required init() throws {
        let idError = ImperialError.missingEnvVar(Auth4sharedAuth.idEnvKey)
        let secretError = ImperialError.missingEnvVar(Auth4sharedAuth.secretEnvKey)

        self.clientID = try Environment.get(Auth4sharedAuth.idEnvKey).value(or: idError)
        self.clientSecret = try Environment.get(Auth4sharedAuth.secretEnvKey).value(or: secretError)
    }
}
