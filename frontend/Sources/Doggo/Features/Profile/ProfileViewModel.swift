import Foundation
import Observation

@MainActor
@Observable
public final class ProfileViewModel {
	public var state: LoadableState<ProfileResponse> = .idle
	public var displayName = ""
	public var avatarUrl = ""

	private let apiClient: APIClient

	public init(apiClient: APIClient) {
		self.apiClient = apiClient
	}

	public func load() async {
		state = .loading
		do {
			let profile: ProfileResponse = try await apiClient.get("/api/profile")
			displayName = profile.displayName
			avatarUrl = profile.avatarUrl ?? ""
			state = .loaded(profile)
		} catch {
			state = .failed(error.localizedDescription)
		}
	}

	public func save() async {
		do {
			let cleanDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
			let cleanAvatarUrl = avatarUrl.trimmingCharacters(in: .whitespacesAndNewlines)
			let profile: ProfileResponse = try await apiClient.put(
				"/api/profile",
				body: UpdateProfileRequest(displayName: cleanDisplayName, avatarUrl: cleanAvatarUrl.isEmpty ? nil : cleanAvatarUrl)
			)
			displayName = profile.displayName
			avatarUrl = profile.avatarUrl ?? ""
			state = .loaded(profile)
		} catch {
			state = .failed(error.localizedDescription)
		}
	}
}
