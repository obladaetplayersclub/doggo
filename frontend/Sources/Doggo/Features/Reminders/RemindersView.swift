import SwiftUI

public struct RemindersView: View {
	@Bindable private var viewModel: RemindersViewModel
	private let petsViewModel: PetsViewModel
	@State private var segment = 0
	@State private var showCreate = false
	@State private var editingReminder: ReminderResponse?

	public init(viewModel: RemindersViewModel, petsViewModel: PetsViewModel) {
		self.viewModel = viewModel
		self.petsViewModel = petsViewModel
	}

	public var body: some View {
		DoggoScreen {
			ScrollView(showsIndicators: false) {
				VStack(alignment: .leading, spacing: 13) {
					header
					DoggoSegmentedPicker(items: ["Сегодня", "Неделя", "Все"], selection: $segment)
					reminderSection(title: "СЕГОДНЯ · \(DateFormatter.doggoDayMonth.string(from: Date()).uppercased())", reminders: todayReminders)
					reminderSection(title: "ДАЛЬШЕ", reminders: laterReminders)
					ErrorBanner(message: viewModel.errorMessage)
				}
				.padding(.horizontal, 14)
				.padding(.top, 30)
				.padding(.bottom, 92)
			}
		}
		.sheet(isPresented: $showCreate) {
			NavigationStack {
				ReminderFormView(viewModel: viewModel, petsViewModel: petsViewModel)
			}
		}
		.sheet(item: $editingReminder) { reminder in
			NavigationStack {
				ReminderFormView(viewModel: viewModel, petsViewModel: petsViewModel, reminder: reminder)
			}
		}
		.task {
			await petsViewModel.loadPets()
			await viewModel.load()
		}
		.refreshable { await viewModel.load() }
	}

	private var header: some View {
		HStack(alignment: .bottom) {
			VStack(alignment: .leading, spacing: 5) {
				Text("Напоминания")
					.font(.system(size: 26, weight: .bold))
					.foregroundStyle(DoggoTheme.text)
				Text("\(todayReminders.count) на сегодня · \(laterReminders.count) на неделе")
					.font(.system(size: 13))
					.foregroundStyle(DoggoTheme.secondaryText)
			}
			Spacer()
			Button {
				showCreate = true
			} label: {
				Image(systemName: "plus")
					.font(.system(size: 18, weight: .bold))
					.foregroundStyle(.white)
					.frame(width: 34, height: 34)
					.background(DoggoTheme.primary)
					.clipShape(Circle())
			}
			.buttonStyle(.plain)
		}
	}

	private var todayReminders: [ReminderResponse] {
		viewModel.reminders.filter { Calendar.current.isDateInToday($0.scheduledAt) }
	}

	private var laterReminders: [ReminderResponse] {
		let todayIds = Set(todayReminders.map(\.id))
		return viewModel.reminders.filter { !todayIds.contains($0.id) }
	}

	private func reminderSection(title: String, reminders: [ReminderResponse]) -> some View {
		VStack(alignment: .leading, spacing: 7) {
			Text(title)
				.font(.system(size: 11, weight: .bold))
				.foregroundStyle(DoggoTheme.secondaryText)
				.padding(.leading, 2)

			DoggoCard {
				VStack(spacing: 0) {
					if reminders.isEmpty {
						Text("Пока нет напоминаний")
							.font(.system(size: 13))
							.foregroundStyle(DoggoTheme.secondaryText)
							.frame(maxWidth: .infinity, minHeight: 54)
					} else {
						ForEach(reminders) { reminder in
							ReminderRow(reminder: reminder) {
								Task { await viewModel.complete(reminder) }
							} onEdit: {
								editingReminder = reminder
							} onDelete: {
								Task { await viewModel.delete(reminder) }
							}
							if reminder.id != reminders.last?.id {
								Divider().background(DoggoTheme.divider)
							}
						}
					}
				}
			}
		}
	}
}

private struct ReminderRow: View {
	let reminder: ReminderResponse
	let onComplete: () -> Void
	let onEdit: () -> Void
	let onDelete: () -> Void

	var body: some View {
		HStack(spacing: 10) {
			Button(action: onComplete) {
				Image(systemName: reminder.status == .completed ? "checkmark.circle.fill" : "circle")
					.font(.system(size: 19, weight: .semibold))
					.foregroundStyle(reminder.status == .completed ? DoggoTheme.primary : DoggoTheme.border)
			}
			.buttonStyle(.plain)

			DoggoIconBubble(systemName: reminder.type.iconName, color: DoggoTheme.background, size: 34)

			VStack(alignment: .leading, spacing: 2) {
				Text(reminder.title)
					.font(.system(size: 14, weight: .bold))
					.foregroundStyle(DoggoTheme.text)
				Text("\(reminder.petName) · \(DateFormatter.doggoTime.string(from: reminder.scheduledAt))")
					.font(.system(size: 11))
					.foregroundStyle(DoggoTheme.secondaryText)
			}

			Spacer()

			Text(DoggoFormatters.relativeReminderTime(reminder.scheduledAt))
				.font(.system(size: 10, weight: .bold))
				.foregroundStyle(DoggoTheme.primary)
				.padding(.horizontal, 8)
				.padding(.vertical, 5)
				.background(DoggoTheme.softGreen)
				.clipShape(Capsule())

			Menu {
				Button("Редактировать", action: onEdit)
				Button("Удалить", role: .destructive, action: onDelete)
			} label: {
				Image(systemName: "ellipsis")
					.font(.system(size: 15, weight: .semibold))
					.foregroundStyle(DoggoTheme.secondaryText)
					.frame(width: 28, height: 28)
			}
			.buttonStyle(.plain)
		}
		.padding(.horizontal, 10)
		.padding(.vertical, 9)
	}
}

private struct ReminderFormView: View {
	@Bindable var viewModel: RemindersViewModel
	let petsViewModel: PetsViewModel
	let reminder: ReminderResponse?
	@Environment(\.dismiss) private var dismiss
	@State private var title = ""
	@State private var selectedPetId: UUID?
	@State private var selectedType: ReminderType = .medication
	@State private var scheduledAt = Date().addingTimeInterval(3600)
	@State private var recurrence: ReminderRecurrence = .weekly
	@State private var notificationEnabled = true
	@State private var note = ""
	@State private var validationMessage: String?

	init(viewModel: RemindersViewModel, petsViewModel: PetsViewModel, reminder: ReminderResponse? = nil) {
		self.viewModel = viewModel
		self.petsViewModel = petsViewModel
		self.reminder = reminder
		_title = State(initialValue: reminder?.title ?? "")
		_selectedPetId = State(initialValue: reminder?.petId)
		_selectedType = State(initialValue: reminder?.type ?? .medication)
		_scheduledAt = State(initialValue: reminder?.scheduledAt ?? Date().addingTimeInterval(3600))
		_recurrence = State(initialValue: reminder?.recurrence ?? .weekly)
		_note = State(initialValue: reminder?.comment ?? "")
	}

	var body: some View {
		DoggoScreen {
			ScrollView(showsIndicators: false) {
				VStack(alignment: .leading, spacing: 13) {
					HStack {
						Spacer()
						Text(reminder == nil ? "Новое напоминание" : "Редактирование")
							.font(.system(size: 15, weight: .bold))
							.foregroundStyle(DoggoTheme.text)
						Spacer()
						Button("Готово") {
							guard let pet = selectedPet else { return }
							guard validate() else { return }
							Task {
								let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
								let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
								if let reminder {
									await viewModel.update(
										reminder,
										pet: pet,
										title: cleanTitle,
										date: scheduledAt,
										type: selectedType,
										recurrence: recurrence,
										comment: cleanNote.isEmpty ? nil : cleanNote,
										notificationEnabled: notificationEnabled
									)
								} else {
									await viewModel.create(
										for: pet,
										title: cleanTitle,
										date: scheduledAt,
										type: selectedType,
										recurrence: recurrence,
										comment: cleanNote.isEmpty ? nil : cleanNote,
										notificationEnabled: notificationEnabled
									)
								}
								dismiss()
							}
						}
						.font(.system(size: 14, weight: .semibold))
						.foregroundStyle(DoggoTheme.primary)
						.disabled(!canSave)
					}
					.padding(.top, 24)

					DoggoEditField(title: "Что напомнить", placeholder: "Капли от блох", text: $title)
					if let validationMessage {
						Text(validationMessage)
							.font(.system(size: 12))
							.foregroundStyle(.red)
					}

					HStack(spacing: 8) {
						VStack(alignment: .leading, spacing: 6) {
							Text("Питомец")
								.font(.system(size: 12))
								.foregroundStyle(DoggoTheme.mutedText)
							Menu(selectedPet?.name ?? "Берта") {
								ForEach(petsViewModel.pets) { pet in
									Button(pet.name) { selectedPetId = pet.id }
								}
							}
							.frame(maxWidth: .infinity)
							.frame(height: 57)
							.background(DoggoTheme.card)
							.clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
						}

						VStack(alignment: .leading, spacing: 6) {
							Text("Категория")
								.font(.system(size: 12))
								.foregroundStyle(DoggoTheme.mutedText)
							Menu(selectedType.displayName) {
								ForEach(ReminderType.allCases) { type in
									Button(type.displayName) { selectedType = type }
								}
							}
							.frame(maxWidth: .infinity)
							.frame(height: 57)
							.background(DoggoTheme.card)
							.clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
						}
					}

					HStack(spacing: 8) {
						DatePicker("Дата", selection: $scheduledAt, displayedComponents: .date)
							.padding(10)
							.frame(maxWidth: .infinity)
							.background(DoggoTheme.card)
							.clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
						DatePicker("Время", selection: $scheduledAt, displayedComponents: .hourAndMinute)
							.padding(10)
							.frame(width: 112)
							.background(DoggoTheme.card)
							.clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
					}
					.font(.system(size: 12))

					recurrenceSelector
					toggles
					DoggoEditField(title: "Заметка", placeholder: "0,5 мл на холку, после еды", text: $note)
				}
				.padding(.horizontal, 13)
				.padding(.bottom, 28)
			}
		}
		.onAppear {
			selectedPetId = selectedPetId ?? petsViewModel.pets.first?.id
		}
	}

	private var selectedPet: PetResponse? {
		petsViewModel.pets.first { $0.id == selectedPetId } ?? petsViewModel.pets.first
	}

	private var canSave: Bool {
		!title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedPet != nil
	}

	private func validate() -> Bool {
		if selectedPet == nil {
			validationMessage = "Сначала добавь питомца."
			return false
		}
		if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			validationMessage = "Укажи название напоминания."
			return false
		}
		validationMessage = nil
		return true
	}

	private var recurrenceSelector: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Повтор")
				.font(.system(size: 12))
				.foregroundStyle(DoggoTheme.mutedText)
			HStack(spacing: 0) {
				ForEach([ReminderRecurrence.none, .daily, .weekly, .monthly]) { item in
					Button {
						recurrence = item
					} label: {
						Text(recurrenceName(item))
							.font(.system(size: 11, weight: recurrence == item ? .bold : .regular))
							.foregroundStyle(recurrence == item ? .white : DoggoTheme.secondaryText)
							.frame(maxWidth: .infinity)
							.frame(height: 30)
							.background(recurrence == item ? DoggoTheme.primary : .clear)
							.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
					}
					.buttonStyle(.plain)
				}
			}
			.padding(3)
			.background(DoggoTheme.card)
			.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
		}
	}

	private var toggles: some View {
		DoggoCard {
			VStack(spacing: 0) {
				Toggle("Локальное уведомление", isOn: $notificationEnabled)
			}
			.font(.system(size: 13))
			.tint(DoggoTheme.primary)
			.padding(.horizontal, 10)
			.padding(.vertical, 8)
		}
	}

	private func recurrenceName(_ value: ReminderRecurrence) -> String {
		switch value {
		case .none: "Нет"
		case .daily: "Ежедн."
		case .weekly: "Неделя"
		case .monthly: "Месяц"
		case .yearly: "Год"
		}
	}
}
