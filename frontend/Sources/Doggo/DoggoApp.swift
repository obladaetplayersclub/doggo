import SwiftUI

@main
public struct DoggoApp: App {
	@State private var appState = AppState()

	public init() {}

	public var body: some Scene {
		WindowGroup {
			RootView()
				.environment(appState)
		}
	}
}
