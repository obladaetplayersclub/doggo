import Foundation

public enum APIError: LocalizedError {
	case invalidURL
	case unauthorized
	case badResponse(status: Int, message: String)
	case decodingFailed
	case noSession

	public var errorDescription: String? {
		switch self {
		case .invalidURL:
			"Invalid server URL."
		case .unauthorized:
			"Please sign in again."
		case let .badResponse(_, message):
			message
		case .decodingFailed:
			"Failed to read server response."
		case .noSession:
			"Session is missing."
		}
	}
}
