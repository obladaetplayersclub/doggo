import SwiftUI

struct ErrorBanner: View {
	let message: String?

	var body: some View {
		if let message {
			Text(message)
				.font(.footnote)
				.foregroundStyle(.red)
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(.vertical, 6)
		}
	}
}

struct EmptyStateView: View {
	let title: String
	let systemImage: String

	var body: some View {
		ContentUnavailableView(title, systemImage: systemImage)
	}
}
