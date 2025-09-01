import Vapor

struct BoxAuth: FederatedServiceTokens {
    static let idEnvKey: String = "BOX_CLIENT_ID"
    static let secretEnvKey: String = "BOX_CLIENT_SECRET"
    let clientID: String
    let clientSecret: String
    
    init() throws {
        guard let clientID = Environment.get(BoxAuth.idEnvKey) else {
            throw ImperialError.missingEnvVar(BoxAuth.idEnvKey)
        }
        self.clientID = clientID

        guard let clientSecret = Environment.get(BoxAuth.secretEnvKey) else {
            throw ImperialError.missingEnvVar(BoxAuth.secretEnvKey)
        }
        self.clientSecret = clientSecret
    }
}
