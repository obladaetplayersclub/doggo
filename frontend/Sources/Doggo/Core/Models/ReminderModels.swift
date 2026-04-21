import Foundation

public enum ReminderType: String, Codable, CaseIterable, Identifiable {
	case medication = "MEDICATION"
	case vaccination = "VACCINATION"
	case visit = "VISIT"
	case care = "CARE"
	case custom = "CUSTOM"

	public var id: String { rawValue }
}

public enum ReminderRecurrence: String, Codable, CaseIterable, Identifiable {
	case none = "NONE"
	case daily = "DAILY"
	case weekly = "WEEKLY"
	case monthly = "MONTHLY"
	case yearly = "YEARLY"

	public var id: String { rawValue }
}

public enum ReminderStatus: String, Codable, CaseIterable, Identifiable {
	case active = "ACTIVE"
	case completed = "COMPLETED"

	public var id: String { rawValue }
}

public struct ReminderUpsertRequest: Encodable {
	public var petId: UUID
	public var type: ReminderType
	public var title: String
	public var scheduledAt: Date
	public var recurrence: ReminderRecurrence
	public var comment: String?
}

public struct ReminderResponse: Decodable, Identifiable, Hashable {
	public let id: UUID
	public let petId: UUID
	public let petName: String
	public let type: ReminderType
	public let title: String
	public let scheduledAt: Date
	public let nextTriggerAt: Date?
	public let lastTriggeredAt: Date?
	public let recurrence: ReminderRecurrence
	public let status: ReminderStatus
	public let comment: String?
	public let completedAt: Date?
}
