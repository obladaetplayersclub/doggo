import Foundation

public struct AuthSession: Codable, Equatable {
	public let token: String
	public let user: UserSummary
}

public struct UserSummary: Codable, Equatable, Identifiable {
	public let id: UUID
	public let email: String
	public let displayName: String
	public let avatarUrl: String?
}
