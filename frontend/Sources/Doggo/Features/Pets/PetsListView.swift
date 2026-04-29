import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
#if os(iOS)
import UIKit
typealias DoggoPlatformImage = UIImage
#else
import AppKit
typealias DoggoPlatformImage = NSImage
#endif

public struct PetsListView: View {
	@Bindable private var viewModel: PetsViewModel

	public init(viewModel: PetsViewModel) {
		self.viewModel = viewModel
	}

	public var body: some View {
		DoggoScreen {
			ScrollView(showsIndicators: false) {
				VStack(alignment: .leading, spacing: 14) {
					header
					todayCard
					pets
					addPetCard
					ErrorBanner(message: viewModel.errorMessage)
				}
				.padding(.horizontal, 16)
				.padding(.top, 22)
				.padding(.bottom, 92)
			}
		}
		.task { await viewModel.loadPets() }
		.refreshable { await viewModel.loadPets() }
	}

	private var header: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack {
				Text("Привет")
					.font(.system(size: 13, weight: .medium))
					.foregroundStyle(DoggoTheme.secondaryText)
				Spacer()
				DoggoIconBubble(systemName: "bell", color: DoggoTheme.card, size: 36)
			}

			Text("Питомцы")
				.font(.system(size: 26, weight: .bold))
				.foregroundStyle(DoggoTheme.text)

			Text("\(DoggoFormatters.petCount(viewModel.pets.count)) на попечении")
				.font(.system(size: 13))
				.foregroundStyle(DoggoTheme.secondaryText)
		}
	}

	private var todayCard: some View {
		DoggoCard {
			HStack(spacing: 12) {
				DoggoIconBubble(systemName: "calendar", color: DoggoTheme.softGreen, size: 38)
				VStack(alignment: .leading, spacing: 3) {
					Text("Сегодня · \(DateFormatter.doggoDayMonth.string(from: Date()))")
						.font(.system(size: 15, weight: .bold))
						.foregroundStyle(DoggoTheme.text)
					Text("Проверь напоминания и прогулки\nдля своих питомцев")
						.font(.system(size: 12))
						.foregroundStyle(DoggoTheme.secondaryText)
				}
				Spacer()
				Image(systemName: "chevron.right")
					.font(.system(size: 13, weight: .semibold))
					.foregroundStyle(DoggoTheme.mutedText)
			}
			.padding(14)
		}
	}

	private var pets: some View {
		VStack(spacing: 12) {
			if viewModel.pets.isEmpty && !viewModel.isLoading {
				DoggoCard {
					EmptyStateView(title: "Питомцев пока нет", systemImage: "pawprint")
						.padding(.vertical, 20)
				}
			}

			ForEach(Array(viewModel.pets.enumerated()), id: \.element.id) { index, pet in
				NavigationLink {
					PetDetailsView(viewModel: viewModel, pet: pet)
				} label: {
					PetListRow(pet: pet, color: petColor(index))
				}
				.buttonStyle(.plain)
			}
		}
	}

	private var addPetCard: some View {
		NavigationLink {
			PetEditView(viewModel: viewModel)
		} label: {
			HStack(spacing: 13) {
				DoggoIconBubble(systemName: "plus", color: DoggoTheme.divider.opacity(0.55), size: 42)
				VStack(alignment: .leading, spacing: 3) {
					Text("Добавить питомца")
						.font(.system(size: 14, weight: .bold))
						.foregroundStyle(DoggoTheme.text)
					Text("Заведи карточку с прививками и\nзаметками")
						.font(.system(size: 12))
						.foregroundStyle(DoggoTheme.secondaryText)
				}
				Spacer()
			}
			.padding(13)
			.overlay {
				RoundedRectangle(cornerRadius: 16, style: .continuous)
					.stroke(DoggoTheme.border.opacity(0.65), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
			}
		}
		.buttonStyle(.plain)
	}

	private func petColor(_ index: Int) -> Color {
		[DoggoTheme.softSand, DoggoTheme.softGreen, DoggoTheme.softRose][index % 3]
	}
}

private struct PetListRow: View {
	let pet: PetResponse
	let color: Color

	var body: some View {
		DoggoCard {
			HStack(spacing: 14) {
				ZStack {
					Circle()
						.fill(color)
					Text("🐶")
						.font(.system(size: 21))
				}
				.frame(width: 56, height: 56)

				VStack(alignment: .leading, spacing: 4) {
					HStack(alignment: .firstTextBaseline, spacing: 5) {
						Text(pet.name)
							.font(.system(size: 17, weight: .bold))
							.foregroundStyle(DoggoTheme.text)
						Text(petAgeText(pet.birthDate))
							.font(.system(size: 12))
							.foregroundStyle(DoggoTheme.secondaryText)
					}
					Text(pet.breed ?? "Порода не указана")
						.font(.system(size: 12))
						.foregroundStyle(DoggoTheme.secondaryText)
					HStack(spacing: 4) {
						Image(systemName: "bell")
						Text(nextHint)
					}
					.font(.system(size: 11, weight: .medium))
					.foregroundStyle(DoggoTheme.secondaryText)
					.padding(.horizontal, 8)
					.padding(.vertical, 4)
					.background(DoggoTheme.divider.opacity(0.45))
					.clipShape(Capsule())
				}
				Spacer()
				Image(systemName: "chevron.right")
					.font(.system(size: 13, weight: .semibold))
					.foregroundStyle(DoggoTheme.mutedText)
			}
			.padding(14)
		}
	}

	private var nextHint: String {
		pet.vaccinations.isEmpty ? "Нет ближайших прививок" : "Прививка запланирована"
	}

	private func petAgeText(_ birthDate: String?) -> String {
		guard let age = DoggoFormatters.age(from: birthDate) else { return "" }
		return "· \(age)"
	}
}

struct PetDetailsView: View {
	@Bindable var viewModel: PetsViewModel
	let pet: PetResponse
	@Environment(\.dismiss) private var dismiss
	@Environment(\.openURL) private var openURL
	@State private var segment = 0
	@State private var showAllergyForm = false
	@State private var showVaccinationForm = false
	@State private var editingVaccination: VaccinationResponse?
	@State private var showAttachmentImporter = false

	var body: some View {
		DoggoScreen {
			ScrollView(showsIndicators: false) {
				VStack(alignment: .leading, spacing: 12) {
					topBar
					petHeader
					DoggoSegmentedPicker(items: ["Обзор", "Прививки", "Аллергии", "Файлы"], selection: $segment)
					stats
					detailRows
					shareButton
				}
				.padding(.horizontal, 15)
				.padding(.top, 31)
				.padding(.bottom, 30)
			}
		}
		.sheet(isPresented: $showAllergyForm) {
			NavigationStack {
				AllergyFormView(viewModel: viewModel, pet: currentPet)
			}
		}
		.sheet(isPresented: $showVaccinationForm) {
			NavigationStack {
				VaccinationFormView(viewModel: viewModel, pet: currentPet)
			}
		}
		.sheet(item: $editingVaccination) { vaccination in
			NavigationStack {
				VaccinationFormView(viewModel: viewModel, pet: currentPet, vaccination: vaccination)
			}
		}
		.fileImporter(
			isPresented: $showAttachmentImporter,
			allowedContentTypes: [.image, .pdf, .data],
			allowsMultipleSelection: false
		) { result in
			Task {
				await uploadImportedAttachment(result)
			}
		}
	}

	private var topBar: some View {
		HStack {
			Button("‹ Назад") { dismiss() }
				.font(.system(size: 14))
				.foregroundStyle(DoggoTheme.primary)
			Spacer()
			NavigationLink {
				PetEditView(viewModel: viewModel, pet: currentPet)
			} label: {
				Image(systemName: "pencil")
					.font(.system(size: 15, weight: .semibold))
					.foregroundStyle(DoggoTheme.primary)
			}
		}
	}

	private var petHeader: some View {
		HStack(spacing: 14) {
			ZStack {
				Circle().fill(DoggoTheme.softSand)
				Text("🦮")
					.font(.system(size: 23))
			}
			.frame(width: 64, height: 64)

			VStack(alignment: .leading, spacing: 3) {
				Text(currentPet.name)
					.font(.system(size: 25, weight: .bold))
					.foregroundStyle(DoggoTheme.text)
				Text("\(currentPet.breed ?? "Порода не указана") · \(currentPet.gender.displayName.lowercased())")
					.font(.system(size: 13))
					.foregroundStyle(DoggoTheme.secondaryText)
				if let age = DoggoFormatters.age(from: currentPet.birthDate) {
					Text(age)
						.font(.system(size: 13))
						.foregroundStyle(DoggoTheme.secondaryText)
				}
			}
		}
		.padding(.top, 10)
	}

	private var stats: some View {
		HStack(spacing: 8) {
			StatCard(title: "Прививки", value: "\(currentPet.vaccinations.count)", subtitle: "записей")
			StatCard(title: "Аллергии", value: "\(currentPet.allergies.count)", subtitle: "указано")
			StatCard(title: "Файлы", value: "\(currentPet.attachments.count)", subtitle: "вложений")
		}
	}

	private var detailRows: some View {
		VStack(spacing: 10) {
			switch segment {
			case 1:
				sectionHeader(title: "Прививки", actionTitle: "Добавить") { showVaccinationForm = true }
				if currentPet.vaccinations.isEmpty {
					emptyMedicalRow("Записей о прививках пока нет")
				} else {
					ForEach(currentPet.vaccinations) { vaccination in
						medicalRow(
							icon: "syringe",
							title: vaccination.name,
							subtitle: "\(vaccination.vaccinationDate)\(vaccination.comment.map { " · \($0)" } ?? "")",
							onEdit: {
								editingVaccination = vaccination
							}
						) {
							Task { await viewModel.deleteVaccination(vaccination, from: currentPet) }
						}
					}
				}
			case 2:
				sectionHeader(title: "Аллергии", actionTitle: "Добавить") { showAllergyForm = true }
				if currentPet.allergies.isEmpty {
					emptyMedicalRow("Аллергии пока не указаны")
				} else {
					ForEach(currentPet.allergies) { allergy in
						medicalRow(icon: "leaf", title: allergy.name, subtitle: "Добавлено \(DateFormatter.doggoDayMonth.string(from: allergy.createdAt))") {
							Task { await viewModel.deleteAllergy(allergy, from: currentPet) }
						}
					}
				}
			case 3:
				Button {
					showAttachmentImporter = true
				} label: {
					Label("Прикрепить файл", systemImage: "paperclip")
						.font(.system(size: 15, weight: .semibold))
						.foregroundStyle(DoggoTheme.primary)
						.frame(maxWidth: .infinity)
						.frame(height: 46)
						.overlay {
							RoundedRectangle(cornerRadius: 12, style: .continuous)
								.stroke(DoggoTheme.border, lineWidth: 1)
						}
				}
				.buttonStyle(.plain)
				if currentPet.attachments.isEmpty {
					emptyMedicalRow("Вложений пока нет")
				} else {
					ForEach(currentPet.attachments) { attachment in
						medicalRow(
							icon: "doc",
							title: attachment.originalFilename,
							subtitle: "\(attachment.contentType) · \(attachment.sizeBytes / 1024) КБ",
							onOpen: {
								let urlString = attachment.downloadUrl.hasPrefix("/")
									? "http://localhost:8080\(attachment.downloadUrl)"
									: attachment.downloadUrl
								if let url = URL(string: urlString) {
									openURL(url)
								}
							}
						) {
							Task { await viewModel.deleteAttachment(attachment, from: currentPet) }
						}
					}
				}
			default:
				PetInfoRow(icon: "syringe", title: "Прививки", meta: "· \(currentPet.vaccinations.count) актуальны", subtitle: currentPet.vaccinations.first.map { "\($0.name) · до \($0.vaccinationDate)" } ?? "Нет записей")
				PetInfoRow(icon: "leaf", title: "Аллергии", meta: "· \(currentPet.allergies.count)", subtitle: currentPet.allergies.map(\.name).prefix(3).joined(separator: ", ").isEmpty ? "Нет аллергий" : currentPet.allergies.map(\.name).prefix(3).joined(separator: ", "))
				PetInfoRow(icon: "doc", title: "Вложения", meta: "· \(currentPet.attachments.count) файлов", subtitle: currentPet.attachments.first?.originalFilename ?? "Нет вложений")
				PetInfoRow(icon: "bell", title: "Напоминания", meta: "", subtitle: "Создай напоминание во вкладке «Напом.»")
			}
		}
	}

	private var currentPet: PetResponse {
		viewModel.pets.first { $0.id == pet.id } ?? pet
	}

	private func sectionHeader(title: String, actionTitle: String, action: @escaping () -> Void) -> some View {
		HStack {
			Text(title)
				.font(.system(size: 15, weight: .bold))
				.foregroundStyle(DoggoTheme.text)
			Spacer()
			Button(actionTitle, action: action)
				.font(.system(size: 13, weight: .semibold))
				.foregroundStyle(DoggoTheme.primary)
		}
	}

	private func emptyMedicalRow(_ title: String) -> some View {
		DoggoCard {
			Text(title)
				.font(.system(size: 13))
				.foregroundStyle(DoggoTheme.secondaryText)
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(12)
		}
	}

	private func uploadImportedAttachment(_ result: Result<[URL], Error>) async {
		guard case let .success(urls) = result,
			  let url = urls.first else {
			return
		}

		let hasAccess = url.startAccessingSecurityScopedResource()
		defer {
			if hasAccess {
				url.stopAccessingSecurityScopedResource()
			}
		}

		do {
			let data = try Data(contentsOf: url)
			let resourceValues = try url.resourceValues(forKeys: [.contentTypeKey])
			let contentType = resourceValues.contentType?.preferredMIMEType ?? "application/octet-stream"
			await viewModel.uploadAttachment(
				to: currentPet,
				data: data,
				filename: url.lastPathComponent,
				contentType: contentType
			)
		} catch {
			viewModel.errorMessage = error.localizedDescription
		}
	}

	private func medicalRow(
		icon: String,
		title: String,
		subtitle: String,
		onOpen: (() -> Void)? = nil,
		onEdit: (() -> Void)? = nil,
		onDelete: @escaping () -> Void
	) -> some View {
		DoggoCard {
			HStack(spacing: 12) {
				DoggoIconBubble(systemName: icon, color: DoggoTheme.background, size: 36)
				VStack(alignment: .leading, spacing: 3) {
					Text(title)
						.font(.system(size: 15, weight: .bold))
						.foregroundStyle(DoggoTheme.text)
					Text(subtitle)
						.font(.system(size: 12))
						.foregroundStyle(DoggoTheme.secondaryText)
						.lineLimit(1)
				}
				Spacer()
				Menu {
					if let onEdit {
						Button("Редактировать", action: onEdit)
					}
					Button("Удалить", role: .destructive, action: onDelete)
				} label: {
					Image(systemName: "ellipsis")
						.font(.system(size: 16, weight: .semibold))
						.foregroundStyle(DoggoTheme.secondaryText)
						.frame(width: 36, height: 36)
				}
			}
			.padding(12)
			.contentShape(Rectangle())
			.onTapGesture {
				onOpen?()
			}
		}
	}

	private var shareButton: some View {
		Button {} label: {
			Label("Поделиться карточкой", systemImage: "qrcode")
				.font(.system(size: 15, weight: .semibold))
				.foregroundStyle(DoggoTheme.text)
				.frame(maxWidth: .infinity)
				.frame(height: 48)
				.overlay {
					RoundedRectangle(cornerRadius: 13, style: .continuous)
						.stroke(DoggoTheme.border, lineWidth: 1)
				}
		}
		.buttonStyle(.plain)
		.padding(.top, 2)
	}
}

private struct AllergyFormView: View {
	@Bindable var viewModel: PetsViewModel
	let pet: PetResponse
	@Environment(\.dismiss) private var dismiss
	@State private var name = ""
	@State private var validationMessage: String?

	var body: some View {
		DoggoScreen {
			VStack(alignment: .leading, spacing: 14) {
				formHeader(title: "Новая аллергия") {
					let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
					guard cleanName.count >= 2 else {
						validationMessage = "Укажи название аллергии."
						return
					}
					Task {
						await viewModel.addAllergy(to: pet, name: cleanName)
						dismiss()
					}
				}
				DoggoEditField(title: "Название", placeholder: "Курица", text: $name)
				if let validationMessage {
					Text(validationMessage)
						.font(.system(size: 12))
						.foregroundStyle(.red)
				}
				Spacer()
			}
			.padding(.horizontal, 16)
			.padding(.top, 28)
		}
	}

	private func formHeader(title: String, onSave: @escaping () -> Void) -> some View {
		HStack {
			Button("‹ Назад") { dismiss() }
				.foregroundStyle(DoggoTheme.primary)
			Spacer()
			Text(title)
				.font(.system(size: 15, weight: .bold))
			Spacer()
			Button("Готово", action: onSave)
				.font(.system(size: 14, weight: .semibold))
				.foregroundStyle(DoggoTheme.primary)
		}
	}
}

private struct VaccinationFormView: View {
	@Bindable var viewModel: PetsViewModel
	let pet: PetResponse
	let vaccination: VaccinationResponse?
	@Environment(\.dismiss) private var dismiss
	@State private var name: String
	@State private var date: Date
	@State private var comment: String
	@State private var validationMessage: String?

	init(viewModel: PetsViewModel, pet: PetResponse, vaccination: VaccinationResponse? = nil) {
		self.viewModel = viewModel
		self.pet = pet
		self.vaccination = vaccination
		_name = State(initialValue: vaccination?.name ?? "")
		_date = State(initialValue: vaccination.flatMap { Self.backendDateFormatter.date(from: $0.vaccinationDate) } ?? Date())
		_comment = State(initialValue: vaccination?.comment ?? "")
	}

	var body: some View {
		DoggoScreen {
			VStack(alignment: .leading, spacing: 14) {
				HStack {
					Button("‹ Назад") { dismiss() }
						.foregroundStyle(DoggoTheme.primary)
					Spacer()
					Text(vaccination == nil ? "Новая прививка" : "Прививка")
						.font(.system(size: 15, weight: .bold))
					Spacer()
					Button("Готово") {
						let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
						guard cleanName.count >= 2 else {
							validationMessage = "Укажи название прививки."
							return
						}
						let cleanComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
						Task {
							if let vaccination {
								await viewModel.updateVaccination(
									vaccination,
									for: pet,
									name: cleanName,
									date: Self.backendDateFormatter.string(from: date),
									comment: cleanComment.isEmpty ? nil : cleanComment
								)
							} else {
								await viewModel.addVaccination(
									to: pet,
									name: cleanName,
									date: Self.backendDateFormatter.string(from: date),
									comment: cleanComment.isEmpty ? nil : cleanComment
								)
							}
							dismiss()
						}
					}
					.font(.system(size: 14, weight: .semibold))
					.foregroundStyle(DoggoTheme.primary)
				}
				DoggoEditField(title: "Название", placeholder: "Nobivac", text: $name)
				DatePicker("Дата прививки", selection: $date, displayedComponents: .date)
					.font(.system(size: 13))
					.padding(12)
					.background(DoggoTheme.card)
					.clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
				DoggoEditField(title: "Комментарий", placeholder: "Повторить через год", text: $comment)
				if let validationMessage {
					Text(validationMessage)
						.font(.system(size: 12))
						.foregroundStyle(.red)
				}
				Spacer()
			}
			.padding(.horizontal, 16)
			.padding(.top, 28)
		}
	}

	private static let backendDateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.calendar = Calendar(identifier: .gregorian)
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.dateFormat = "yyyy-MM-dd"
		return formatter
	}()
}

private struct StatCard: View {
	let title: String
	let value: String
	let subtitle: String

	var body: some View {
		DoggoCard {
			VStack(alignment: .leading, spacing: 4) {
				Text(title)
					.font(.system(size: 11))
					.foregroundStyle(DoggoTheme.secondaryText)
				Text(value)
					.font(.system(size: 19, weight: .bold))
					.foregroundStyle(DoggoTheme.text)
				Text(subtitle)
					.font(.system(size: 10))
					.foregroundStyle(DoggoTheme.secondaryText)
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding(12)
		}
	}
}

private struct PetInfoRow: View {
	let icon: String
	let title: String
	let meta: String
	let subtitle: String

	var body: some View {
		DoggoCard {
			HStack(spacing: 12) {
				DoggoIconBubble(systemName: icon, color: DoggoTheme.background, size: 36)
				VStack(alignment: .leading, spacing: 3) {
					HStack(spacing: 4) {
						Text(title)
							.font(.system(size: 15, weight: .bold))
							.foregroundStyle(DoggoTheme.text)
						Text(meta)
							.font(.system(size: 12))
							.foregroundStyle(DoggoTheme.secondaryText)
					}
					Text(subtitle)
						.font(.system(size: 12))
						.foregroundStyle(DoggoTheme.secondaryText)
						.lineLimit(1)
				}
				Spacer()
				Image(systemName: "chevron.right")
					.font(.system(size: 13, weight: .semibold))
					.foregroundStyle(DoggoTheme.mutedText)
			}
			.padding(12)
		}
	}
}

struct PetEditView: View {
	@Bindable var viewModel: PetsViewModel
	let pet: PetResponse?
	@Environment(\.dismiss) private var dismiss
	@State private var name: String
	@State private var breed: String
	@State private var gender: PetGender
	@State private var birthDate: String
	@State private var notes: String
	@State private var weight = "6,2"
	@State private var chip = "643 098 100 000 000"
	@State private var allergy = "курица"
	@State private var validationMessage: String?
	@State private var selectedPhotoItem: PhotosPickerItem?
	@State private var selectedPhotoData: Data?

	init(viewModel: PetsViewModel, pet: PetResponse? = nil) {
		self.viewModel = viewModel
		self.pet = pet
		_name = State(initialValue: pet?.name ?? "")
		_breed = State(initialValue: pet?.breed ?? "")
		_gender = State(initialValue: pet?.gender ?? .male)
		_birthDate = State(initialValue: pet?.birthDate ?? "")
		_notes = State(initialValue: pet?.notes ?? "")
	}

	var body: some View {
		DoggoScreen {
			ScrollView(showsIndicators: false) {
				VStack(spacing: 13) {
					HStack {
						Spacer()
						Text(pet == nil ? "Новый питомец" : "Питомец")
							.font(.system(size: 15, weight: .bold))
							.foregroundStyle(DoggoTheme.text)
						Spacer()
						Button("Готово") {
							Task {
								guard validate() else {
									return
								}
								let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
								let cleanBreed = breed.trimmingCharacters(in: .whitespacesAndNewlines)
								let cleanBirthDate = birthDate.trimmingCharacters(in: .whitespacesAndNewlines)
								let cleanNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
								if let pet {
									await viewModel.updatePet(
										pet,
										name: cleanName,
										breed: cleanBreed.isEmpty ? nil : cleanBreed,
										birthDate: cleanBirthDate.isEmpty ? nil : cleanBirthDate,
										gender: gender,
										photoUrl: photoDataURL,
										notes: cleanNotes.isEmpty ? nil : cleanNotes
									)
								} else {
									await viewModel.createPet(
										name: cleanName,
										breed: cleanBreed.isEmpty ? nil : cleanBreed,
										birthDate: cleanBirthDate.isEmpty ? nil : cleanBirthDate,
										gender: gender,
										photoUrl: photoDataURL,
										notes: cleanNotes.isEmpty ? nil : cleanNotes
									)
								}
								dismiss()
							}
						}
						.font(.system(size: 14, weight: .semibold))
						.foregroundStyle(DoggoTheme.primary)
						.disabled(!canSave)
					}
					.padding(.top, 31)

					PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
						VStack(spacing: 8) {
							ZStack(alignment: .bottomTrailing) {
								photoPreview
								DoggoIconBubble(systemName: "camera", color: DoggoTheme.primary, size: 32)
									.foregroundStyle(.white)
									.offset(x: 3, y: 3)
							}
							Text(selectedPhotoData == nil && pet?.photoUrl == nil ? "Загрузить фото" : "Изменить фото")
								.font(.system(size: 12))
								.foregroundStyle(DoggoTheme.secondaryText)
						}
					}
					.buttonStyle(.plain)
					.padding(.top, 10)
					.onChange(of: selectedPhotoItem) { _, newItem in
						Task {
							selectedPhotoData = try? await newItem?.loadTransferable(type: Data.self)
						}
					}

					EditField(title: "Кличка", placeholder: "Тоби", text: $name)
					if let validationMessage {
						Text(validationMessage)
							.font(.system(size: 12))
							.foregroundStyle(.red)
							.frame(maxWidth: .infinity, alignment: .leading)
					}

					HStack(spacing: 8) {
						EditField(title: "Порода", placeholder: "Бигль", text: $breed)
						VStack(alignment: .leading, spacing: 6) {
							Text("Пол")
								.font(.system(size: 12))
								.foregroundStyle(DoggoTheme.mutedText)
							Menu {
								ForEach(PetGender.allCases) { item in
									Button(item.displayName) { gender = item }
								}
							} label: {
								HStack {
									Text(gender.displayName)
									Spacer()
									Image(systemName: "chevron.down")
								}
								.font(.system(size: 13))
								.foregroundStyle(DoggoTheme.text)
								.padding(.horizontal, 12)
								.frame(height: 57)
								.background(DoggoTheme.card)
								.clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
							}
						}
						.frame(width: 90)
					}

					HStack(spacing: 8) {
						EditField(title: "Дата рождения", placeholder: "14.03.2025", text: $birthDate, systemImage: "calendar")
						EditField(title: "Вес, кг", placeholder: "6,2", text: $weight)
							.frame(width: 90)
					}

					EditField(title: "Чип / клеймо", placeholder: "643 098 100 000 000", text: $chip)
					EditField(title: "Заметки", placeholder: "Особенности ухода, питание, характер", text: $notes)

					VStack(alignment: .leading, spacing: 7) {
						Text("Аллергии")
							.font(.system(size: 12))
							.foregroundStyle(DoggoTheme.mutedText)
						HStack(spacing: 8) {
							DoggoChip(title: "\(allergy)  ×", isSelected: false)
							DoggoChip(title: "пыльца  ×", isSelected: false)
							DoggoChip(title: "+ добавить", isSelected: false)
							Spacer()
						}
						.padding(10)
						.background(DoggoTheme.card)
						.clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
					}
				}
				.padding(.horizontal, 17)
				.padding(.bottom, 28)
			}
		}
	}

	private var canSave: Bool {
		let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
		return cleanName.count >= 2
	}

	@ViewBuilder
	private var photoPreview: some View {
		if let selectedPhotoData, let image = DoggoPlatformImage(data: selectedPhotoData) {
			platformImage(image)
		} else if let photoUrl = pet?.photoUrl, let url = URL(string: photoUrl), url.scheme?.hasPrefix("http") == true {
			AsyncImage(url: url) { image in
				image
					.resizable()
					.scaledToFill()
			} placeholder: {
				photoPlaceholder
			}
			.frame(width: 88, height: 88)
			.clipShape(Circle())
		} else {
			photoPlaceholder
		}
	}

	@ViewBuilder
	private func platformImage(_ image: DoggoPlatformImage) -> some View {
		#if os(iOS)
		Image(uiImage: image)
			.resizable()
			.scaledToFill()
			.frame(width: 88, height: 88)
			.clipShape(Circle())
		#else
		Image(nsImage: image)
			.resizable()
			.scaledToFill()
			.frame(width: 88, height: 88)
			.clipShape(Circle())
		#endif
	}

	private var photoPlaceholder: some View {
		ZStack {
			Circle()
				.fill(DoggoTheme.softSand)
				.frame(width: 88, height: 88)
			Image(systemName: "pawprint.fill")
				.font(.system(size: 31))
				.foregroundStyle(DoggoTheme.primary)
		}
	}

	private var photoDataURL: String? {
		guard let selectedPhotoData else {
			return nil
		}
		return "data:image/jpeg;base64,\(selectedPhotoData.base64EncodedString())"
	}

	private func validate() -> Bool {
		let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
		if cleanName.count < 2 {
			validationMessage = "Кличка должна быть не короче 2 символов."
			return false
		}
		validationMessage = nil
		return true
	}
}

private struct EditField: View {
	let title: String
	let placeholder: String
	@Binding var text: String
	var systemImage: String?

	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			Text(title)
				.font(.system(size: 12))
				.foregroundStyle(DoggoTheme.mutedText)
			HStack {
				TextField(placeholder, text: $text)
					.font(.system(size: 14))
					.foregroundStyle(DoggoTheme.text)
				if let systemImage {
					Image(systemName: systemImage)
						.font(.system(size: 13))
						.foregroundStyle(DoggoTheme.secondaryText)
				}
			}
			.padding(.horizontal, 12)
			.frame(height: 57)
			.background(DoggoTheme.card)
			.clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
		}
	}
}
