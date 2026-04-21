import Foundation

@MainActor
public final class APIClient {
	public var baseURL: URL
	public var authToken: String?

	private let session: URLSession
	private let decoder: JSONDecoder
	private let encoder: JSONEncoder

	public init(
		baseURL: URL = URL(string: "http://localhost:8080")!,
		session: URLSession = .shared
	) {
		self.baseURL = baseURL
		self.session = session
		self.decoder = JSONDecoder.doggo
		self.encoder = JSONEncoder.doggo
	}

	public func get<Response: Decodable>(_ path: String, queryItems: [URLQueryItem] = []) async throws -> Response {
		try await request(path, method: "GET", queryItems: queryItems)
	}

	public func post<Request: Encodable, Response: Decodable>(_ path: String, body: Request) async throws -> Response {
		try await request(path, method: "POST", body: body)
	}

	public func postEmpty(_ path: String) async throws {
		let _: EmptyResponse = try await request(path, method: "POST")
	}

	public func postEmptyReturning<Response: Decodable>(_ path: String) async throws -> Response {
		try await request(path, method: "POST")
	}

	public func put<Request: Encodable, Response: Decodable>(_ path: String, body: Request) async throws -> Response {
		try await request(path, method: "PUT", body: body)
	}

	public func delete(_ path: String) async throws {
		let _: EmptyResponse = try await request(path, method: "DELETE")
	}

	public func uploadMultipart<Response: Decodable>(
		_ path: String,
		fileData: Data,
		fieldName: String = "file",
		filename: String,
		contentType: String
	) async throws -> Response {
		guard let components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false),
			  let url = components.url else {
			throw APIError.invalidURL
		}

		let boundary = "DoggoBoundary-\(UUID().uuidString)"
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Accept")
		request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
		if let authToken {
			request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
		}

		var body = Data()
		body.append("--\(boundary)\r\n".data(using: .utf8)!)
		body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
		body.append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
		body.append(fileData)
		body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
		request.httpBody = body

		let (data, response) = try await session.data(for: request)
		guard let httpResponse = response as? HTTPURLResponse else {
			throw APIError.badResponse(status: 0, message: "Server did not return HTTP response.")
		}
		guard (200..<300).contains(httpResponse.statusCode) else {
			throw decodeError(data: data, status: httpResponse.statusCode)
		}
		do {
			return try decoder.decode(Response.self, from: data)
		} catch {
			throw APIError.decodingFailed
		}
	}

	private func request<Response: Decodable, Request: Encodable>(
		_ path: String,
		method: String,
		queryItems: [URLQueryItem] = [],
		body: Request
	) async throws -> Response {
		guard var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false) else {
			throw APIError.invalidURL
		}
		components.queryItems = queryItems.isEmpty ? nil : queryItems
		guard let url = components.url else {
			throw APIError.invalidURL
		}

		var request = URLRequest(url: url)
		request.httpMethod = method
		request.setValue("application/json", forHTTPHeaderField: "Accept")
		if let authToken {
			request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
		}
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = try encoder.encode(body)

		let (data, response) = try await session.data(for: request)
		guard let httpResponse = response as? HTTPURLResponse else {
			throw APIError.badResponse(status: 0, message: "Server did not return HTTP response.")
		}
		if httpResponse.statusCode == 204, Response.self == EmptyResponse.self {
			return EmptyResponse() as! Response
		}
		guard (200..<300).contains(httpResponse.statusCode) else {
			throw decodeError(data: data, status: httpResponse.statusCode)
		}
		do {
			return try decoder.decode(Response.self, from: data)
		} catch {
			throw APIError.decodingFailed
		}
	}

	private func request<Response: Decodable>(
		_ path: String,
		method: String,
		queryItems: [URLQueryItem] = []
	) async throws -> Response {
		guard var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false) else {
			throw APIError.invalidURL
		}
		components.queryItems = queryItems.isEmpty ? nil : queryItems
		guard let url = components.url else {
			throw APIError.invalidURL
		}

		var request = URLRequest(url: url)
		request.httpMethod = method
		request.setValue("application/json", forHTTPHeaderField: "Accept")
		if let authToken {
			request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
		}

		let (data, response) = try await session.data(for: request)
		guard let httpResponse = response as? HTTPURLResponse else {
			throw APIError.badResponse(status: 0, message: "Server did not return HTTP response.")
		}
		if httpResponse.statusCode == 204, Response.self == EmptyResponse.self {
			return EmptyResponse() as! Response
		}
		guard (200..<300).contains(httpResponse.statusCode) else {
			throw decodeError(data: data, status: httpResponse.statusCode)
		}
		do {
			return try decoder.decode(Response.self, from: data)
		} catch {
			throw APIError.decodingFailed
		}
	}

	private func decodeError(data: Data, status: Int) -> APIError {
		if status == 401 {
			return .unauthorized
		}
		if let apiError = try? decoder.decode(APIErrorResponse.self, from: data) {
			return .badResponse(status: status, message: apiError.message)
		}
		return .badResponse(status: status, message: "Request failed with status \(status).")
	}
}

private struct EmptyResponse: Decodable {}

private struct APIErrorResponse: Decodable {
	let message: String
}
