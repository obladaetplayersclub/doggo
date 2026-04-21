import SwiftUI

struct DoggoScreen<Content: View>: View {
	@ViewBuilder var content: Content

	var body: some View {
		ZStack {
			DoggoTheme.background.ignoresSafeArea()
			content
		}
		#if os(iOS)
		.toolbar(.hidden, for: .navigationBar)
		#endif
	}
}

struct DoggoCard<Content: View>: View {
	var cornerRadius: CGFloat = 16
	@ViewBuilder var content: Content

	var body: some View {
		content
			.background(DoggoTheme.card)
			.clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
	}
}

struct DoggoIconBubble: View {
	let systemName: String
	var color: Color = DoggoTheme.softGreen
	var size: CGFloat = 38

	var body: some View {
		ZStack {
			Circle()
				.fill(color)
			Image(systemName: systemName)
				.font(.system(size: size * 0.38, weight: .semibold))
				.foregroundStyle(DoggoTheme.primary)
		}
		.frame(width: size, height: size)
	}
}

struct DoggoChip: View {
	let title: String
	var isSelected = false

	var body: some View {
		Text(title)
			.font(.system(size: 11, weight: isSelected ? .semibold : .medium))
			.foregroundStyle(isSelected ? .white : DoggoTheme.secondaryText)
			.padding(.horizontal, 12)
			.padding(.vertical, 7)
			.background(isSelected ? DoggoTheme.primary : DoggoTheme.card)
			.clipShape(Capsule())
	}
}

struct DoggoSegmentedPicker: View {
	let items: [String]
	@Binding var selection: Int

	var body: some View {
		HStack(spacing: 0) {
			ForEach(items.indices, id: \.self) { index in
				Button {
					selection = index
				} label: {
					Text(items[index])
						.font(.system(size: 12, weight: selection == index ? .semibold : .regular))
						.foregroundStyle(selection == index ? DoggoTheme.text : DoggoTheme.secondaryText)
						.frame(maxWidth: .infinity)
						.frame(height: 30)
						.background(selection == index ? DoggoTheme.card : .clear)
						.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
				}
				.buttonStyle(.plain)
			}
		}
		.padding(3)
		.background(DoggoTheme.divider.opacity(0.45))
		.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
	}
}

struct DoggoEditField: View {
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

extension DateFormatter {
	static let doggoTime: DateFormatter = {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "ru_RU")
		formatter.dateFormat = "HH:mm"
		return formatter
	}()

	static let doggoDayMonth: DateFormatter = {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "ru_RU")
		formatter.dateFormat = "d MMMM"
		return formatter
	}()
}

enum DoggoFormatters {
	static func petCount(_ count: Int) -> String {
		let suffix: String
		if count % 10 == 1 && count % 100 != 11 {
			suffix = "питомец"
		} else if (2...4).contains(count % 10) && !(12...14).contains(count % 100) {
			suffix = "питомца"
		} else {
			suffix = "питомцев"
		}
		return "\(count) \(suffix)"
	}

	static func age(from birthDate: String?) -> String? {
		guard
			let birthDate,
			let year = Int(birthDate.prefix(4)),
			let month = Int(birthDate.dropFirst(5).prefix(2)),
			let day = Int(birthDate.dropFirst(8).prefix(2)),
			let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: day))
		else {
			return nil
		}
		let components = Calendar.current.dateComponents([.year, .month], from: date, to: Date())
		if let years = components.year, years > 0 {
			return "\(years) \(years == 1 ? "год" : "лет")"
		}
		if let months = components.month, months > 0 {
			return "\(months) мес."
		}
		return "меньше месяца"
	}

	static func distance(_ meters: Double) -> String {
		if meters >= 1000 {
			return String(format: "%.1f км", meters / 1000)
		}
		return "\(Int(meters.rounded())) м"
	}

	static func duration(_ seconds: Int64) -> String {
		let hours = seconds / 3600
		let minutes = (seconds % 3600) / 60
		let remainingSeconds = seconds % 60
		return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
	}

	static func relativeReminderTime(_ date: Date) -> String {
		let minutes = Int(date.timeIntervalSinceNow / 60)
		if minutes < -1 {
			return "просрочено"
		}
		if minutes <= 1 {
			return "сейчас"
		}
		if minutes < 60 {
			return "через \(minutes)м"
		}
		if minutes < 24 * 60 {
			return "через \(minutes / 60)ч"
		}
		return DateFormatter.doggoDayMonth.string(from: date)
	}
}

extension ReminderType {
	var displayName: String {
		switch self {
		case .medication: "Лекарство"
		case .vaccination: "Прививка"
		case .visit: "Визит"
		case .care: "Уход"
		case .custom: "Другое"
		}
	}

	var iconName: String {
		switch self {
		case .medication: "pills"
		case .vaccination: "syringe"
		case .visit: "stethoscope"
		case .care: "pawprint"
		case .custom: "bell"
		}
	}
}

extension PlaceCategory {
	var displayName: String {
		switch self {
		case .vetClinic: "Ветклиники"
		case .grooming: "Груминг"
		case .walkArea: "Парки"
		case .other: "Кафе"
		}
	}

	var mapIcon: String {
		switch self {
		case .vetClinic: "cross.case.fill"
		case .grooming: "scissors"
		case .walkArea: "pawprint.fill"
		case .other: "cup.and.saucer.fill"
		}
	}
}

extension PetGender {
	var displayName: String {
		switch self {
		case .male: "Самец"
		case .female: "Самка"
		case .unknown: "Не указан"
		}
	}
}
