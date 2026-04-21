import Foundation

public struct RegisterRequest: Encodable {
	public var email: String
	public var password: String
	public var displayName: String
}

public struct LoginRequest: Encodable {
	public var email: String
	public var password: String
}

public struct UpdateProfileRequest: Encodable {
	public var displayName: String
	public var avatarUrl: String?
}

public struct ProfileResponse: Decodable, Identifiable {
	public let id: UUID
	public let email: String
	public let displayName: String
	public let avatarUrl: String?
	public let petCount: Int
}
