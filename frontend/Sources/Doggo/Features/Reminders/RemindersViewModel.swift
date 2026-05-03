import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
public final class RemindersViewModel {
	public var reminders: [ReminderResponse] = []
	public var statusFilter: ReminderStatus?
	public var isLoading = false
	public var errorMessage: String?

	private let apiClient: APIClient
	private let notificationScheduler = LocalReminderNotificationScheduler()

	public init(apiClient: APIClient) {
		self.apiClient = apiClient
	}

	public func requestNotificationAuthorization() {
		notificationScheduler.requestAuthorization()
	}

	public func load() async {
		isLoading = true
		errorMessage = nil
		defer { isLoading = false }

		do {
			var queryItems: [URLQueryItem] = []
			if let statusFilter {
				queryItems.append(URLQueryItem(name: "status", value: statusFilter.rawValue))
			}
			reminders = try await apiClient.get("/api/reminders", queryItems: queryItems)
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	public func create(
		for pet: PetResponse,
		title: String,
		date: Date,
		type: ReminderType = .custom,
		recurrence: ReminderRecurrence = .none,
		comment: String? = nil,
		notificationEnabled: Bool = true
	) async {
		do {
			let created: ReminderResponse = try await apiClient.post(
				"/api/reminders",
				body: ReminderUpsertRequest(
					petId: pet.id,
					type: type,
					title: title,
					scheduledAt: date,
					recurrence: recurrence,
					comment: comment
				)
			)
			reminders.append(created)
			reminders.sort { $0.scheduledAt < $1.scheduledAt }
			if notificationEnabled {
				notificationScheduler.schedule(created)
			}
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	public func update(
		_ reminder: ReminderResponse,
		pet: PetResponse,
		title: String,
		date: Date,
		type: ReminderType,
		recurrence: ReminderRecurrence,
		comment: String?,
		notificationEnabled: Bool = true
	) async {
		do {
			let updated: ReminderResponse = try await apiClient.put(
				"/api/reminders/\(reminder.id.uuidString)",
				body: ReminderUpsertRequest(
					petId: pet.id,
					type: type,
					title: title,
					scheduledAt: date,
					recurrence: recurrence,
					comment: comment
				)
			)
			if let index = reminders.firstIndex(where: { $0.id == updated.id }) {
				reminders[index] = updated
			}
			reminders.sort { $0.scheduledAt < $1.scheduledAt }
			notificationScheduler.cancel(reminder.id)
			if notificationEnabled {
				notificationScheduler.schedule(updated)
			}
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	public func complete(_ reminder: ReminderResponse) async {
		do {
			let completed: ReminderResponse = try await apiClient.postEmptyReturning(
				"/api/reminders/\(reminder.id.uuidString)/complete"
			)
			if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
				reminders[index] = completed
			}
			notificationScheduler.cancel(reminder.id)
			if completed.status == .active {
				notificationScheduler.schedule(completed)
			}
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	public func delete(_ reminder: ReminderResponse) async {
		do {
			try await apiClient.delete("/api/reminders/\(reminder.id.uuidString)")
			reminders.removeAll { $0.id == reminder.id }
			notificationScheduler.cancel(reminder.id)
		} catch {
			errorMessage = error.localizedDescription
		}
	}
}

private final class LocalReminderNotificationScheduler {
	private let center = UNUserNotificationCenter.current()

	func requestAuthorization() {
		center.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
	}

	func schedule(_ reminder: ReminderResponse) {
		guard reminder.status == .active else {
			return
		}

		let content = UNMutableNotificationContent()
		content.title = reminder.title
		content.body = "\(reminder.petName): пора выполнить напоминание."
		content.sound = .default

		let request = UNNotificationRequest(
			identifier: identifier(for: reminder.id),
			content: content,
			trigger: trigger(for: reminder)
		)
		center.add(request) { _ in }
	}

	func cancel(_ reminderId: UUID) {
		center.removePendingNotificationRequests(withIdentifiers: [identifier(for: reminderId)])
		center.removeDeliveredNotifications(withIdentifiers: [identifier(for: reminderId)])
	}

	private func identifier(for reminderId: UUID) -> String {
		"doggo-reminder-\(reminderId.uuidString)"
	}

	private func trigger(for reminder: ReminderResponse) -> UNNotificationTrigger {
		if reminder.recurrence == .none {
			return UNTimeIntervalNotificationTrigger(
				timeInterval: max(1, reminder.scheduledAt.timeIntervalSinceNow),
				repeats: false
			)
		}

		var components: Set<Calendar.Component> = [.hour, .minute]
		switch reminder.recurrence {
		case .daily:
			break
		case .weekly:
			components.insert(.weekday)
		case .monthly:
			components.insert(.day)
		case .yearly:
			components.insert(.month)
			components.insert(.day)
		case .none:
			break
		}
		let dateComponents = Calendar.current.dateComponents(components, from: reminder.scheduledAt)
		return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
	}
}
