import Vapor

public class BoxAuth: FederatedServiceTokens {
    public static var idEnvKey: String = "BOX_CLIENT_ID"
    public static var secretEnvKey: String = "BOX_CLIENT_SECRET"
    public var clientID: String
    public var clientSecret: String
    
    public required init() throws {
        let idError = ImperialError.missingEnvVar(BoxAuth.idEnvKey)
        let secretError = ImperialError.missingEnvVar(BoxAuth.secretEnvKey)
        
        self.clientID = try Environment.get(BoxAuth.idEnvKey).value(or: idError)
        self.clientSecret = try Environment.get(BoxAuth.secretEnvKey).value(or: secretError)
    }
}
