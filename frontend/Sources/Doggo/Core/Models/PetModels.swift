import Foundation

public enum PetGender: String, Codable, CaseIterable, Identifiable {
	case male = "MALE"
	case female = "FEMALE"
	case unknown = "UNKNOWN"

	public var id: String { rawValue }
}

public struct PetUpsertRequest: Encodable {
	public var name: String
	public var breed: String?
	public var birthDate: String?
	public var gender: PetGender
	public var photoUrl: String?
	public var notes: String?
}

public struct AllergyCreateRequest: Encodable {
	public var name: String
}

public struct VaccinationUpsertRequest: Encodable {
	public var name: String
	public var vaccinationDate: String
	public var comment: String?
}

public struct PetResponse: Decodable, Identifiable, Hashable {
	public let id: UUID
	public let name: String
	public let breed: String?
	public let birthDate: String?
	public let gender: PetGender
	public let photoUrl: String?
	public let notes: String?
	public let createdAt: Date
	public let updatedAt: Date
	public let allergies: [AllergyResponse]
	public let vaccinations: [VaccinationResponse]
	public let attachments: [AttachmentResponse]
}

public struct AllergyResponse: Decodable, Identifiable, Hashable {
	public let id: UUID
	public let name: String
	public let createdAt: Date
}

public struct VaccinationResponse: Decodable, Identifiable, Hashable {
	public let id: UUID
	public let name: String
	public let vaccinationDate: String
	public let comment: String?
	public let createdAt: Date
}

public struct AttachmentResponse: Decodable, Identifiable, Hashable {
	public let id: UUID
	public let originalFilename: String
	public let contentType: String
	public let sizeBytes: Int64
	public let downloadUrl: String
	public let createdAt: Date
}
