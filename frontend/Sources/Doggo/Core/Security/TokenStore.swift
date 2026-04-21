import Foundation
import Security

public protocol TokenStore {
	func load() -> AuthSession?
	func save(_ session: AuthSession)
	func clear()
}

public final class KeychainTokenStore: TokenStore {
	private let service = "com.doggo.app.session"
	private let account = "current"
	private let fallback = UserDefaultsTokenStore()

	public init() {}

	public func load() -> AuthSession? {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: account,
			kSecReturnData as String: true,
			kSecMatchLimit as String: kSecMatchLimitOne
		]
		var item: CFTypeRef?
		let status = SecItemCopyMatching(query as CFDictionary, &item)
		guard status == errSecSuccess, let data = item as? Data else {
			return fallback.load()
		}
		return try? JSONDecoder.doggo.decode(AuthSession.self, from: data)
	}

	public func save(_ session: AuthSession) {
		guard let data = try? JSONEncoder.doggo.encode(session) else {
			return
		}
		clear()
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: account,
			kSecValueData as String: data
		]
		let status = SecItemAdd(query as CFDictionary, nil)
		if status != errSecSuccess {
			fallback.save(session)
		}
	}

	public func clear() {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: account
		]
		SecItemDelete(query as CFDictionary)
		fallback.clear()
	}
}

private final class UserDefaultsTokenStore: TokenStore {
	private let key = "doggo.auth.session"

	func load() -> AuthSession? {
		guard let data = UserDefaults.standard.data(forKey: key) else {
			return nil
		}
		return try? JSONDecoder.doggo.decode(AuthSession.self, from: data)
	}

	func save(_ session: AuthSession) {
		let data = try? JSONEncoder.doggo.encode(session)
		UserDefaults.standard.set(data, forKey: key)
	}

	func clear() {
		UserDefaults.standard.removeObject(forKey: key)
	}
}
