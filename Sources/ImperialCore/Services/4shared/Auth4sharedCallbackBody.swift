import Vapor

public protocol Auth4sharedStampable : Content {
    var oauth_signature_method : String { get set }
    var oauth_timestamp: String { get set }
    var oauth_nonce: String { get set }
}

public extension Auth4sharedStampable {
    mutating func stamp() {
        oauth_signature_method  = "PLAINTEXT" // Reasonable over HTTPS, IMHO
        oauth_timestamp = String(Int(Date().timeIntervalSince1970))
        oauth_nonce = UUID().uuidString
    }
}

struct Auth4sharedInitiateBody: Auth4sharedStampable {
    let oauth_consumer_key: String
    let oauth_signature: String
    var oauth_signature_method = ""
    var oauth_timestamp = ""
    var oauth_nonce = ""

    init(oauth_consumer_key: String, oauth_signature: String) {
        self.oauth_consumer_key = oauth_consumer_key
        self.oauth_signature = oauth_signature

        stamp()
    }
}

struct Auth4sharedTokenResponse : Decodable {
    let oauth_token: String
    let oauth_token_secret: String
}

public protocol Auth4sharedSignature {
    var oauth_token: String { get set}
    var oauth_consumer_key: String { get set }
    var oauth_signature: String { get set }
}

public struct Auth4sharedSignatureParam : Auth4sharedSignature, Codable {
    public var oauth_token: String
    public var oauth_consumer_key: String
    public var oauth_signature: String

    public init(oauth_token: String, oauth_consumer_key: String, oauth_signature: String) {
        self.oauth_token = oauth_token
        self.oauth_consumer_key = oauth_consumer_key
        self.oauth_signature = oauth_signature
    }
}

public protocol Auth4sharedSignable : Auth4sharedStampable, Auth4sharedSignature {
}

public extension Auth4sharedSignable {
    mutating func sign(signature: Auth4sharedSignature) {
        oauth_token = signature.oauth_token
        oauth_consumer_key = signature.oauth_consumer_key
        oauth_signature = signature.oauth_signature

        stamp()
    }
}

public struct Auth4sharedCallbackBody: Auth4sharedSignable {
    public var oauth_token = ""
    public var oauth_consumer_key = ""
    public var oauth_signature = ""
    public var oauth_signature_method = ""
    public var oauth_timestamp = ""
    public var oauth_nonce = ""

    public init(signature: Auth4sharedSignature) {
        sign(signature: signature)
    }
}
