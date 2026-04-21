import Foundation
import Observation

@MainActor
@Observable
public final class AppState {
	public var session: AuthSession?
	public var authViewModel: AuthViewModel
	public var petsViewModel: PetsViewModel
	public var remindersViewModel: RemindersViewModel
	public var placesViewModel: PlacesViewModel
	public var profileViewModel: ProfileViewModel
	public var locationManager: LocationManager

	let apiClient: APIClient
	private let tokenStore: TokenStore

	public init(
		apiClient: APIClient = APIClient(),
		tokenStore: TokenStore = KeychainTokenStore()
	) {
		self.apiClient = apiClient
		self.tokenStore = tokenStore
		self.session = tokenStore.load()
		self.authViewModel = AuthViewModel(apiClient: apiClient, tokenStore: tokenStore)
		self.petsViewModel = PetsViewModel(apiClient: apiClient)
		self.remindersViewModel = RemindersViewModel(apiClient: apiClient)
		self.placesViewModel = PlacesViewModel(apiClient: apiClient)
		self.profileViewModel = ProfileViewModel(apiClient: apiClient)
		self.locationManager = LocationManager()
		self.remindersViewModel.requestNotificationAuthorization()
		self.authViewModel.onSessionChange = { [weak self] session in
			self?.session = session
			self?.apiClient.authToken = session?.token
		}
		self.apiClient.authToken = session?.token
	}
}
