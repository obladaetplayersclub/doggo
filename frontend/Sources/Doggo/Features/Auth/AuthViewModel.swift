import Foundation
import Observation

@MainActor
@Observable
public final class AuthViewModel {
	public var email = ""
	public var password = ""
	public var displayName = ""
	public var isRegisterMode = false
	public var isLoading = false
	public var errorMessage: String?
	public var onSessionChange: ((AuthSession?) -> Void)?

	private let apiClient: APIClient
	private let tokenStore: TokenStore

	public init(apiClient: APIClient, tokenStore: TokenStore) {
		self.apiClient = apiClient
		self.tokenStore = tokenStore
	}

	public func submit() async {
		let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
		let cleanDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
		guard cleanEmail.contains("@") else {
			errorMessage = "Введите корректный email."
			return
		}
		guard password.count >= 8 else {
			errorMessage = "Пароль должен быть не короче 8 символов."
			return
		}
		if isRegisterMode, cleanDisplayName.count < 2 {
			errorMessage = "Имя должно быть не короче 2 символов."
			return
		}

		isLoading = true
		errorMessage = nil
		defer { isLoading = false }

		do {
			let session: AuthSession
			if isRegisterMode {
				session = try await apiClient.post(
					"/api/auth/register",
					body: RegisterRequest(email: cleanEmail, password: password, displayName: cleanDisplayName)
				)
			} else {
				session = try await apiClient.post(
					"/api/auth/login",
					body: LoginRequest(email: cleanEmail, password: password)
				)
			}
			tokenStore.save(session)
			onSessionChange?(session)
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	public func logout() async {
		do {
			try await apiClient.postEmpty("/api/auth/logout")
		} catch {
		}
		tokenStore.clear()
		onSessionChange?(nil)
	}
}
