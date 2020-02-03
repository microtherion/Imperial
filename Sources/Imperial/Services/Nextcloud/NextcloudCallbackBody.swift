import Vapor

struct NextcloudCallbackBody: Content {
    let server: String
    let loginName: String
    let appPassword: String

    static var defaultContentType: MediaType = .json
}
