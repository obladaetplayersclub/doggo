import SwiftUI

public struct MainTabView: View {
	@Environment(AppState.self) private var appState

	public var body: some View {
		TabView {
			NavigationStack {
				PetsListView(viewModel: appState.petsViewModel)
			}
			.tabItem {
				Label("Питомцы", systemImage: "pawprint")
			}

			NavigationStack {
				RemindersView(viewModel: appState.remindersViewModel, petsViewModel: appState.petsViewModel)
			}
			.tabItem {
				Label("Напом.", systemImage: "bell.badge")
			}

			NavigationStack {
				PlacesView(
					viewModel: appState.placesViewModel,
					locationManager: appState.locationManager,
					currentUserId: appState.session?.user.id
				)
			}
			.tabItem {
				Label("Места", systemImage: "map")
			}

			NavigationStack {
				WalksHomeView(
					petsViewModel: appState.petsViewModel,
					apiClient: appState.apiClient,
					locationManager: appState.locationManager
				)
			}
			.tabItem {
				Label("Прогулка", systemImage: "figure.walk")
			}

			NavigationStack {
				ProfileView(viewModel: appState.profileViewModel, authViewModel: appState.authViewModel)
			}
			.tabItem {
				Label("Профиль", systemImage: "person.crop.circle")
			}
		}
		.tint(DoggoTheme.primary)
	}
}
