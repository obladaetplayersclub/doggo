import SwiftUI

public struct RootView: View {
	@Environment(AppState.self) private var appState

	public init() {}

	public var body: some View {
		Group {
			if appState.session == nil {
				AuthView(viewModel: appState.authViewModel)
			} else {
				MainTabView()
			}
		}
	}
}
