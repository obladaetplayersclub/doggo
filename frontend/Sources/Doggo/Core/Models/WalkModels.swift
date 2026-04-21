import Foundation

public enum WalkStatus: String, Codable {
	case active = "ACTIVE"
	case finished = "FINISHED"
}

public struct StartWalkRequest: Encodable {
	public var startedAt: Date?
}

public struct FinishWalkRequest: Encodable {
	public var endedAt: Date?
}

public struct WalkPointRequest: Encodable {
	public var latitude: Double
	public var longitude: Double
	public var recordedAt: Date
}

public struct AddWalkPointsRequest: Encodable {
	public var points: [WalkPointRequest]
}

public struct WalkResponse: Decodable, Identifiable, Hashable {
	public let id: UUID
	public let petId: UUID
	public let petName: String
	public let startedAt: Date
	public let endedAt: Date?
	public let distanceMeters: Double
	public let durationSeconds: Int64
	public let status: WalkStatus
}

public struct WalkStatsResponse: Decodable, Hashable {
	public let petId: UUID
	public let totalWalks: Int64
	public let totalDistanceMeters: Double
	public let totalDurationSeconds: Int64
}
