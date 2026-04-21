import SwiftUI

enum DoggoTheme {
	static let background = Color(red: 0.94, green: 0.92, blue: 0.88)
	static let surface = Color(red: 1.00, green: 0.99, blue: 0.96)
	static let card = Color(red: 1.00, green: 0.99, blue: 0.95)
	static let text = Color(red: 0.13, green: 0.12, blue: 0.10)
	static let secondaryText = Color(red: 0.58, green: 0.54, blue: 0.49)
	static let mutedText = Color(red: 0.69, green: 0.65, blue: 0.58)
	static let primary = Color(red: 0.44, green: 0.55, blue: 0.42)
	static let primaryPressed = Color(red: 0.36, green: 0.47, blue: 0.34)
	static let softGreen = Color(red: 0.84, green: 0.90, blue: 0.80)
	static let softSand = Color(red: 0.90, green: 0.82, blue: 0.64)
	static let softRose = Color(red: 0.84, green: 0.68, blue: 0.61)
	static let border = Color(red: 0.87, green: 0.83, blue: 0.75)
	static let divider = Color(red: 0.88, green: 0.84, blue: 0.76)
	static let heroGreen = Color(red: 0.88, green: 0.91, blue: 0.83)
	static let heroSand = Color(red: 0.92, green: 0.86, blue: 0.72)
	static let lineArt = Color(red: 0.56, green: 0.58, blue: 0.51)
}

struct DoggoPrimaryButtonStyle: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.font(.system(size: 15, weight: .semibold))
			.foregroundStyle(.white)
			.frame(maxWidth: .infinity)
			.frame(height: 50)
			.background(configuration.isPressed ? DoggoTheme.primaryPressed : DoggoTheme.primary)
			.clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
			.opacity(configuration.isPressed ? 0.92 : 1)
	}
}

struct DoggoSecondaryButtonStyle: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.font(.system(size: 15, weight: .medium))
			.foregroundStyle(DoggoTheme.text)
			.frame(maxWidth: .infinity)
			.frame(height: 50)
			.background(DoggoTheme.background)
			.overlay {
				RoundedRectangle(cornerRadius: 13, style: .continuous)
					.stroke(DoggoTheme.border, lineWidth: 1)
			}
			.clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
			.opacity(configuration.isPressed ? 0.7 : 1)
	}
}
