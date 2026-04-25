import SwiftUI

public struct ProfileView: View {
	@Bindable private var viewModel: ProfileViewModel
	private let authViewModel: AuthViewModel
	@State private var showEditProfile = false

	public init(viewModel: ProfileViewModel, authViewModel: AuthViewModel) {
		self.viewModel = viewModel
		self.authViewModel = authViewModel
	}

	public var body: some View {
		DoggoScreen {
			ScrollView(showsIndicators: false) {
				VStack(alignment: .leading, spacing: 16) {
					Text("Профиль")
						.font(.system(size: 29, weight: .heavy))
						.foregroundStyle(DoggoTheme.text)
						.padding(.top, 30)

					profileCard
					stats
					settingsSection(title: "АККАУНТ", rows: accountRows)
					settingsSection(title: "ПРИЛОЖЕНИЕ", rows: appRows)

					Button("Выйти") {
						Task { await authViewModel.logout() }
					}
					.font(.system(size: 14, weight: .semibold))
					.foregroundStyle(.red)
					.frame(maxWidth: .infinity)
					.frame(height: 48)
					.background(DoggoTheme.card)
					.clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

					if case let .failed(message) = viewModel.state {
						ErrorBanner(message: message)
					}
				}
				.padding(.horizontal, 17)
				.padding(.bottom, 92)
			}
		}
		.task { await viewModel.load() }
		.sheet(isPresented: $showEditProfile) {
			NavigationStack {
				ProfileEditView(viewModel: viewModel)
			}
		}
	}

	private var profile: ProfileResponse? {
		viewModel.state.value
	}

	private var profileCard: some View {
		Button {
			showEditProfile = true
		} label: {
			DoggoCard {
				HStack(spacing: 14) {
					ZStack {
						Circle()
							.fill(DoggoTheme.softRose.opacity(0.75))
						Text(String((profile?.displayName ?? "А").prefix(1)))
							.font(.system(size: 22, weight: .bold))
							.foregroundStyle(DoggoTheme.secondaryText)
					}
					.frame(width: 58, height: 58)

					VStack(alignment: .leading, spacing: 3) {
						Text(profile?.displayName ?? "Профиль")
							.font(.system(size: 18, weight: .bold))
							.foregroundStyle(DoggoTheme.text)
						Text(profile?.email ?? "Данные загружаются")
							.font(.system(size: 13))
							.foregroundStyle(DoggoTheme.secondaryText)
						Text("\(DoggoFormatters.petCount(profile?.petCount ?? 0))")
							.font(.system(size: 12, weight: .medium))
							.foregroundStyle(DoggoTheme.secondaryText)
					}
					Spacer()
					Image(systemName: "chevron.right")
						.font(.system(size: 13, weight: .semibold))
						.foregroundStyle(DoggoTheme.mutedText)
				}
				.padding(13)
			}
		}
		.buttonStyle(.plain)
	}

	private var stats: some View {
		HStack(spacing: 9) {
			ProfileStat(value: "\(profile?.petCount ?? 0)", label: "Питомцев")
			ProfileStat(value: "0 км", label: "Дистанция")
			ProfileStat(value: "0", label: "Мест")
		}
	}

	private var accountRows: [ProfileRowData] {
		[
			ProfileRowData(icon: "person", title: "Личные данные", value: nil),
			ProfileRowData(icon: "pawprint", title: "Мои питомцы", value: "\(profile?.petCount ?? 0)"),
			ProfileRowData(icon: "bell", title: "Уведомления", value: "Вкл."),
			ProfileRowData(icon: "qrcode", title: "Поделиться карточкой", value: nil)
		]
	}

	private var appRows: [ProfileRowData] {
		[
			ProfileRowData(icon: "gearshape", title: "Единицы измерения", value: "км · кг"),
			ProfileRowData(icon: "map", title: "Карта по умолчанию", value: "Apple Maps"),
			ProfileRowData(icon: "icloud", title: "Резервная копия", value: "не настроена")
		]
	}

	private func settingsSection(title: String, rows: [ProfileRowData]) -> some View {
		VStack(alignment: .leading, spacing: 7) {
			Text(title)
				.font(.system(size: 12, weight: .bold))
				.foregroundStyle(DoggoTheme.secondaryText)
				.padding(.leading, 5)

			DoggoCard {
				VStack(spacing: 0) {
					ForEach(rows) { row in
						ProfileSettingsRow(row: row)
						if row.id != rows.last?.id {
							Divider().background(DoggoTheme.divider)
						}
					}
				}
			}
		}
	}
}

private struct ProfileEditView: View {
	@Bindable var viewModel: ProfileViewModel
	@Environment(\.dismiss) private var dismiss
	@State private var validationMessage: String?

	var body: some View {
		DoggoScreen {
			VStack(alignment: .leading, spacing: 14) {
				HStack {
					Button("‹ Назад") { dismiss() }
						.font(.system(size: 14))
						.foregroundStyle(DoggoTheme.primary)
					Spacer()
					Text("Личные данные")
						.font(.system(size: 15, weight: .bold))
						.foregroundStyle(DoggoTheme.text)
					Spacer()
					Button("Готово") {
						guard validate() else {
							return
						}
						Task {
							await viewModel.save()
							dismiss()
						}
					}
					.font(.system(size: 14, weight: .semibold))
					.foregroundStyle(DoggoTheme.primary)
				}
				.padding(.top, 30)

				DoggoEditField(title: "Имя", placeholder: "Анна Соколова", text: $viewModel.displayName)
				DoggoEditField(title: "Ссылка на аватар", placeholder: "Необязательно", text: $viewModel.avatarUrl)

				if let validationMessage {
					Text(validationMessage)
						.font(.system(size: 12))
						.foregroundStyle(.red)
				}

				Spacer()
			}
			.padding(.horizontal, 16)
		}
	}

	private func validate() -> Bool {
		if viewModel.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			validationMessage = "Имя обязательно."
			return false
		}
		validationMessage = nil
		return true
	}
}

private struct ProfileStat: View {
	let value: String
	let label: String

	var body: some View {
		DoggoCard {
			VStack(spacing: 3) {
				Text(value)
					.font(.system(size: 19, weight: .heavy))
					.foregroundStyle(DoggoTheme.text)
				Text(label)
					.font(.system(size: 11))
					.foregroundStyle(DoggoTheme.secondaryText)
			}
			.frame(maxWidth: .infinity)
			.frame(height: 64)
		}
	}
}

private struct ProfileRowData: Identifiable {
	let id = UUID()
	let icon: String
	let title: String
	let value: String?
}

private struct ProfileSettingsRow: View {
	let row: ProfileRowData

	var body: some View {
		HStack(spacing: 12) {
			DoggoIconBubble(systemName: row.icon, color: DoggoTheme.background, size: 31)
			Text(row.title)
				.font(.system(size: 14, weight: .medium))
				.foregroundStyle(DoggoTheme.text)
			Spacer()
			if let value = row.value {
				Text(value)
					.font(.system(size: 12))
					.foregroundStyle(DoggoTheme.secondaryText)
			}
			Image(systemName: "chevron.right")
				.font(.system(size: 12, weight: .semibold))
				.foregroundStyle(DoggoTheme.mutedText)
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 11)
	}
}
