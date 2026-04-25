import SwiftUI

public struct AuthView: View {
	@Bindable private var viewModel: AuthViewModel
	@State private var screen: AuthScreen = .welcome
	@State private var acceptedTerms = true

	public init(viewModel: AuthViewModel) {
		self.viewModel = viewModel
	}

	public var body: some View {
		ZStack {
			DoggoTheme.background.ignoresSafeArea()

			switch screen {
			case .welcome:
				WelcomeAuthScreen(
					onCreateAccount: {
						viewModel.isRegisterMode = true
						screen = .register
					},
					onLogin: {
						viewModel.isRegisterMode = false
						screen = .login
					}
				)
			case .login:
				LoginAuthScreen(
					viewModel: viewModel,
					onBack: { screen = .welcome },
					onRegister: {
						viewModel.isRegisterMode = true
						screen = .register
					}
				)
			case .register:
				RegisterAuthScreen(
					viewModel: viewModel,
					acceptedTerms: $acceptedTerms,
					onBack: { screen = .welcome }
				)
			}
		}
		.animation(.snappy(duration: 0.28), value: screen)
	}
}

private enum AuthScreen {
	case welcome
	case login
	case register
}

private struct WelcomeAuthScreen: View {
	let onCreateAccount: () -> Void
	let onLogin: () -> Void

	var body: some View {
		ScrollView(showsIndicators: false) {
			VStack(alignment: .leading, spacing: 0) {
				DoggoHeroCard()
					.frame(height: 278)
					.padding(.top, 34)

				Text("Заботься о своём\nхвостике проще")
					.font(.system(size: 26, weight: .bold))
					.foregroundStyle(DoggoTheme.text)
					.lineSpacing(-1)
					.padding(.top, 26)

				Text("Прививки, прогулки, напоминания\nи любимые места — в одном приложении.")
					.font(.system(size: 14))
					.foregroundStyle(DoggoTheme.secondaryText)
					.lineSpacing(3)
					.padding(.top, 8)

				VStack(spacing: 10) {
					Button("Создать аккаунт", action: onCreateAccount)
						.buttonStyle(DoggoPrimaryButtonStyle())

					Button("Уже есть аккаунт", action: onLogin)
						.buttonStyle(DoggoSecondaryButtonStyle())
				}
				.padding(.top, 22)

				SocialLoginBlock(caption: "или")
					.padding(.top, 22)
			}
			.padding(.horizontal, 17)
			.padding(.bottom, 24)
		}
	}
}

private struct LoginAuthScreen: View {
	@Bindable var viewModel: AuthViewModel
	let onBack: () -> Void
	let onRegister: () -> Void

	var body: some View {
		AuthScrollContainer {
			AuthTopBar(title: "Вход", onBack: onBack)

			Text("С возвращением 👋")
				.authTitle()
				.padding(.top, 20)

			Text("Войди, чтобы продолжить заботиться о\nхвостике.")
				.authSubtitle()
				.padding(.top, 3)

			VStack(alignment: .leading, spacing: 12) {
				AuthTextField(title: "Email", placeholder: "anna@example.com", text: $viewModel.email, inputStyle: .email)

				AuthPasswordField(title: "Пароль", placeholder: "Минимум 8 символов", text: $viewModel.password)

				Button("Забыли пароль?") {}
					.font(.system(size: 12))
					.foregroundStyle(DoggoTheme.mutedText)
					.frame(maxWidth: .infinity, alignment: .trailing)
					.padding(.top, -4)
			}
			.padding(.top, 22)

			AuthErrorView(message: viewModel.errorMessage)

			Button {
				viewModel.isRegisterMode = false
				Task { await viewModel.submit() }
			} label: {
				AuthButtonLabel(title: "Войти", isLoading: viewModel.isLoading)
			}
			.buttonStyle(DoggoPrimaryButtonStyle())
			.disabled(viewModel.isLoading)
			.padding(.top, viewModel.errorMessage == nil ? 4 : 10)

			Button {
				viewModel.isRegisterMode = true
				onRegister()
			} label: {
				Text("Нет аккаунта? ")
					.foregroundStyle(DoggoTheme.secondaryText)
				+ Text("Зарегистрируйся")
					.foregroundStyle(DoggoTheme.primary)
					.fontWeight(.semibold)
			}
			.font(.system(size: 13))
			.frame(maxWidth: .infinity)
			.padding(.top, 12)

			Spacer(minLength: 98)

			SocialLoginBlock(caption: "или войти через")
		}
	}
}

private struct RegisterAuthScreen: View {
	@Bindable var viewModel: AuthViewModel
	@Binding var acceptedTerms: Bool
	let onBack: () -> Void

	var body: some View {
		AuthScrollContainer {
			AuthTopBar(title: "Регистрация", onBack: onBack)

			Text("Заведём профиль")
				.authTitle()
				.padding(.top, 20)

			Text("Пара полей — и можно добавлять питомца.")
				.authSubtitle()
				.padding(.top, 4)

			VStack(alignment: .leading, spacing: 12) {
				AuthTextField(title: "Как тебя зовут", placeholder: "Анна", text: $viewModel.displayName, inputStyle: .name)

				AuthTextField(title: "Email", placeholder: "anna@example.com", text: $viewModel.email, inputStyle: .email)

				AuthPasswordField(title: "Пароль", placeholder: "Минимум 8 символов", text: $viewModel.password)

				Button {
					acceptedTerms.toggle()
				} label: {
					HStack(alignment: .top, spacing: 8) {
						Image(systemName: acceptedTerms ? "checkmark.square.fill" : "square")
							.font(.system(size: 17, weight: .semibold))
							.foregroundStyle(acceptedTerms ? DoggoTheme.primary : DoggoTheme.mutedText)
							.padding(.top, 1)

						Text("Соглашаюсь с условиями использования и\nобработкой данных.")
							.font(.system(size: 12))
							.foregroundStyle(DoggoTheme.secondaryText)
							.lineSpacing(2)
							.frame(maxWidth: .infinity, alignment: .leading)
					}
				}
				.buttonStyle(.plain)
				.padding(.top, 2)
			}
			.padding(.top, 21)

			AuthErrorView(message: viewModel.errorMessage)

			Button {
				viewModel.isRegisterMode = true
				Task { await viewModel.submit() }
			} label: {
				AuthButtonLabel(title: "Создать аккаунт", isLoading: viewModel.isLoading)
			}
			.buttonStyle(DoggoPrimaryButtonStyle())
			.disabled(viewModel.isLoading || !acceptedTerms)
			.opacity(acceptedTerms ? 1 : 0.55)
			.padding(.top, viewModel.errorMessage == nil ? 22 : 10)

			Spacer(minLength: 24)
		}
	}
}

private struct AuthScrollContainer<Content: View>: View {
	@ViewBuilder var content: Content

	var body: some View {
		ScrollView(showsIndicators: false) {
			VStack(alignment: .leading, spacing: 0) {
				content
			}
			.frame(maxWidth: .infinity, minHeight: 760, alignment: .topLeading)
			.padding(.horizontal, 16)
			.padding(.top, 32)
			.padding(.bottom, 28)
		}
	}
}

private struct AuthTopBar: View {
	let title: String
	let onBack: () -> Void

	var body: some View {
		ZStack {
			Text(title)
				.font(.system(size: 15, weight: .semibold))
				.foregroundStyle(DoggoTheme.text)
				.frame(maxWidth: .infinity)

			Button(action: onBack) {
				Text("‹ Назад")
					.font(.system(size: 14))
					.foregroundStyle(DoggoTheme.primary)
			}
			.frame(maxWidth: .infinity, alignment: .leading)
		}
		.frame(height: 28)
	}
}

private struct DoggoHeroCard: View {
	var body: some View {
		ZStack(alignment: .topLeading) {
			LinearGradient(
				colors: [DoggoTheme.heroGreen, DoggoTheme.heroSand],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
			.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

			Text("DOGGO · BETA")
				.font(.system(size: 10, weight: .bold))
				.tracking(1.1)
				.foregroundStyle(DoggoTheme.secondaryText)
				.padding(.horizontal, 11)
				.padding(.vertical, 7)
				.background(.white.opacity(0.64))
				.clipShape(Capsule())
				.padding(.top, 21)
				.padding(.leading, 21)

			DogLineArtView()
				.stroke(DoggoTheme.lineArt, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
				.frame(width: 158, height: 102)
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
				.padding(.trailing, 20)
				.padding(.bottom, 22)
		}
	}
}

private struct DogLineArtView: Shape {
	func path(in rect: CGRect) -> Path {
		var path = Path()
		let w = rect.width
		let h = rect.height

		path.move(to: CGPoint(x: 0.04 * w, y: 0.64 * h))
		path.addCurve(
			to: CGPoint(x: 0.29 * w, y: 0.16 * h),
			control1: CGPoint(x: 0.05 * w, y: 0.38 * h),
			control2: CGPoint(x: 0.14 * w, y: 0.18 * h)
		)
		path.addCurve(
			to: CGPoint(x: 0.68 * w, y: 0.20 * h),
			control1: CGPoint(x: 0.43 * w, y: 0.09 * h),
			control2: CGPoint(x: 0.55 * w, y: 0.25 * h)
		)
		path.addCurve(
			to: CGPoint(x: 0.81 * w, y: 0.08 * h),
			control1: CGPoint(x: 0.74 * w, y: 0.19 * h),
			control2: CGPoint(x: 0.78 * w, y: 0.14 * h)
		)
		path.addLine(to: CGPoint(x: 0.86 * w, y: 0.19 * h))
		path.addLine(to: CGPoint(x: 0.94 * w, y: 0.08 * h))
		path.addCurve(
			to: CGPoint(x: 0.77 * w, y: 0.75 * h),
			control1: CGPoint(x: 1.00 * w, y: 0.50 * h),
			control2: CGPoint(x: 0.91 * w, y: 0.71 * h)
		)
		path.addLine(to: CGPoint(x: 0.75 * w, y: 0.94 * h))
		path.addLine(to: CGPoint(x: 0.69 * w, y: 0.94 * h))
		path.addLine(to: CGPoint(x: 0.68 * w, y: 0.76 * h))
		path.addLine(to: CGPoint(x: 0.41 * w, y: 0.76 * h))
		path.addLine(to: CGPoint(x: 0.41 * w, y: 0.94 * h))
		path.addLine(to: CGPoint(x: 0.35 * w, y: 0.94 * h))
		path.addLine(to: CGPoint(x: 0.34 * w, y: 0.72 * h))
		path.addLine(to: CGPoint(x: 0.04 * w, y: 0.64 * h))

		path.move(to: CGPoint(x: 0.85 * w, y: 0.31 * h))
		path.addEllipse(in: CGRect(x: 0.835 * w, y: 0.295 * h, width: 0.035 * w, height: 0.035 * w))

		return path
	}
}

private struct AuthTextField: View {
	let title: String
	let placeholder: String
	@Binding var text: String
	var inputStyle: DoggoTextInputStyle = .standard

	var body: some View {
		VStack(alignment: .leading, spacing: 7) {
			Text(title)
				.authFieldTitle()

			TextField(placeholder, text: $text)
				.font(.system(size: 14))
				.foregroundStyle(DoggoTheme.text)
				.doggoTextInput(inputStyle)
				.padding(.horizontal, 12)
				.frame(height: 58)
				.background(DoggoTheme.surface)
				.clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
		}
	}
}

private struct AuthPasswordField: View {
	let title: String
	let placeholder: String
	@Binding var text: String
	@State private var isSecured = true

	var body: some View {
		VStack(alignment: .leading, spacing: 7) {
			Text(title)
				.authFieldTitle()

			HStack(spacing: 8) {
				Group {
					if isSecured {
						SecureField(placeholder, text: $text)
					} else {
						TextField(placeholder, text: $text)
					}
				}
				.font(.system(size: 14))
				.foregroundStyle(DoggoTheme.text)

				Button {
					isSecured.toggle()
				} label: {
					Image(systemName: isSecured ? "eye" : "eye.slash")
						.font(.system(size: 15))
						.foregroundStyle(DoggoTheme.mutedText)
				}
			}
			.padding(.horizontal, 12)
			.frame(height: 58)
			.background(DoggoTheme.surface)
			.clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
		}
	}
}

private struct AuthButtonLabel: View {
	let title: String
	let isLoading: Bool

	var body: some View {
		Group {
			if isLoading {
				ProgressView()
					.tint(.white)
			} else {
				Text(title)
			}
		}
	}
}

private struct AuthErrorView: View {
	let message: String?

	var body: some View {
		if let message {
			Text(message)
				.font(.system(size: 12))
				.foregroundStyle(.red)
				.padding(.top, 12)
				.frame(maxWidth: .infinity, alignment: .leading)
		}
	}
}

private struct SocialLoginBlock: View {
	let caption: String

	var body: some View {
		VStack(spacing: 14) {
			HStack(spacing: 10) {
				Rectangle()
					.fill(DoggoTheme.divider)
					.frame(height: 1)

				Text(caption)
					.font(.system(size: 11))
					.foregroundStyle(DoggoTheme.mutedText)
					.fixedSize()

				Rectangle()
					.fill(DoggoTheme.divider)
					.frame(height: 1)
			}

			HStack(spacing: 9) {
				SocialButton(kind: .apple)
				SocialButton(kind: .google)
			}
		}
	}
}

private struct SocialButton: View {
	let kind: SocialKind

	var body: some View {
		Button {} label: {
			HStack(spacing: 10) {
				switch kind {
				case .apple:
					Image(systemName: "apple.logo")
						.font(.system(size: 17, weight: .semibold))
						.foregroundStyle(.black)
				case .google:
					Text("G")
						.font(.system(size: 16, weight: .bold))
						.foregroundStyle(
							LinearGradient(
								colors: [.blue, .red, .yellow, .green],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
				}

				Text(kind.title)
					.font(.system(size: 15, weight: .medium))
					.foregroundStyle(DoggoTheme.text)
			}
			.frame(maxWidth: .infinity)
			.frame(height: 46)
			.background(DoggoTheme.background)
			.overlay {
				RoundedRectangle(cornerRadius: 12, style: .continuous)
					.stroke(DoggoTheme.border, lineWidth: 1)
			}
			.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
		}
		.buttonStyle(.plain)
	}
}

private enum SocialKind {
	case apple
	case google

	var title: String {
		switch self {
		case .apple: "Apple"
		case .google: "Google"
		}
	}
}

private extension Text {
	func authTitle() -> some View {
		self
			.font(.system(size: 23, weight: .bold))
			.foregroundStyle(DoggoTheme.text)
	}

	func authSubtitle() -> some View {
		self
			.font(.system(size: 13))
			.foregroundStyle(DoggoTheme.secondaryText)
			.lineSpacing(2)
	}

	func authFieldTitle() -> some View {
		self
			.font(.system(size: 12))
			.foregroundStyle(DoggoTheme.mutedText)
	}
}
