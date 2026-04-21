import Foundation

public enum PlaceCategory: String, Codable, CaseIterable, Identifiable {
	case vetClinic = "VET_CLINIC"
	case grooming = "GROOMING"
	case walkArea = "WALK_AREA"
	case other = "OTHER"

	public var id: String { rawValue }
}

public enum ReviewStatus: String, Codable {
	case underModeration = "UNDER_MODERATION"
	case published = "PUBLISHED"
	case rejected = "REJECTED"
}

public struct ReviewUpsertRequest: Encodable {
	public var rating: Int
	public var text: String
}

public struct ReviewComplaintRequest: Encodable {
	public var reason: String
}

public struct PlaceSummaryResponse: Decodable, Identifiable, Hashable {
	public let id: UUID
	public let name: String
	public let address: String
	public let description: String?
	public let category: PlaceCategory
	public let district: String?
	public let metroStation: String?
	public let latitude: Double
	public let longitude: Double
	public let distanceMeters: Double?
	public let averageRating: Double
	public let reviewCount: Int
}

public struct PlaceDetailsResponse: Decodable, Identifiable {
	public let id: UUID
	public let name: String
	public let address: String
	public let description: String?
	public let category: PlaceCategory
	public let district: String?
	public let metroStation: String?
	public let latitude: Double
	public let longitude: Double
	public let averageRating: Double
	public let reviewCount: Int
	public let reviews: [ReviewResponse]
}

public struct ReviewResponse: Decodable, Identifiable, Hashable {
	public let id: UUID
	public let authorId: UUID
	public let authorDisplayName: String
	public let rating: Int
	public let text: String
	public let status: ReviewStatus
	public let complaintCount: Int
	public let createdAt: Date
	public let updatedAt: Date
}
