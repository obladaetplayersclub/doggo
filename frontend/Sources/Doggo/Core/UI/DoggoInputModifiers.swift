import SwiftUI

enum DoggoTextInputStyle {
	case standard
	case email
	case name
	case url
}

extension View {
	@ViewBuilder
	func doggoTextInput(_ style: DoggoTextInputStyle) -> some View {
		#if os(iOS)
		switch style {
		case .standard:
			self
		case .email:
			self
				.textInputAutocapitalization(.never)
				.keyboardType(.emailAddress)
				.autocorrectionDisabled()
		case .name:
			self
				.textInputAutocapitalization(.words)
		case .url:
			self
				.textInputAutocapitalization(.never)
				.keyboardType(.URL)
				.autocorrectionDisabled()
		}
		#else
		self
		#endif
	}
}

