import Vapor

extension Session.Keys {
    static let cloudDomain = "cloud_domain"
    static let nextcloudPollURL = "nextcloud_poll"
    static let nextcloudPollToken = "nextcloud_poll_token"
    static let nextcloudUserID = "nextcloud_user_id"
}

extension Session {
    public func cloudDomain() throws -> String {
        guard let domain = self[Keys.cloudDomain] else { throw Abort(.notFound) }
        return domain
    }
    
    func setCloudDomain(_ domain: String) {
        self[Keys.cloudDomain] = domain
    }

    func nextcloudPollURL() throws -> String {
        guard let url = self[Keys.nextcloudPollURL] else { throw Abort(.notFound) }
        return url
    }

    func setNextcloudPollURL(_ url: String) {
        self[Keys.nextcloudPollURL] = url
    }

    func nextcloudPollToken() throws -> String {
        guard let token = self[Keys.nextcloudPollToken] else { throw Abort(.notFound) }
        return token
    }

    func setNextcloudPollToken(_ token: String) {
        self[Keys.nextcloudPollToken] = token
    }

    public func nextcloudUserID() throws -> String {
        guard let uid = self[Keys.nextcloudUserID] else { throw Abort(.notFound) }
        return uid
    }

    func setNextcloudUserID(_ uid: String) {
        self[Keys.nextcloudUserID] = uid
    }

}
