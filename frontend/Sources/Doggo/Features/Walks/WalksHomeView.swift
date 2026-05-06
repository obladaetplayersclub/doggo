import SwiftUI
import MapKit

public struct WalksHomeView: View {
	private let petsViewModel: PetsViewModel
	private let apiClient: APIClient
	@Bindable private var locationManager: LocationManager

	public init(petsViewModel: PetsViewModel, apiClient: APIClient, locationManager: LocationManager) {
		self.petsViewModel = petsViewModel
		self.apiClient = apiClient
		self.locationManager = locationManager
	}

	public var body: some View {
		DoggoScreen {
			if let pet = petsViewModel.pets.first {
				WalkActiveView(
					viewModel: WalksViewModel(apiClient: apiClient, pet: pet),
					pet: pet,
					locationManager: locationManager
				)
			} else {
				VStack(spacing: 14) {
					EmptyStateView(title: "Добавь питомца для прогулок", systemImage: "figure.walk")
					NavigationLink("Перейти к питомцам") {
						EmptyView()
					}
					.buttonStyle(DoggoPrimaryButtonStyle())
					.padding(.horizontal, 24)
				}
			}
		}
		.task { await petsViewModel.loadPets() }
	}
}

private struct WalkActiveView: View {
	@Bindable var viewModel: WalksViewModel
	let pet: PetResponse
	@Bindable var locationManager: LocationManager
	@State private var now = Date()
	@State private var lastPointSentAt: Date?
	@State private var mapPosition: MapCameraPosition = .region(
		MKCoordinateRegion(
			center: CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6173),
			span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
		)
	)

	var body: some View {
		ZStack(alignment: .bottom) {
			walkMap
				.ignoresSafeArea()

			VStack {
				HStack {
					Button {
						Task { await viewModel.finish() }
					} label: {
						Image(systemName: "xmark")
							.font(.system(size: 14, weight: .bold))
							.foregroundStyle(DoggoTheme.text)
							.frame(width: 42, height: 42)
							.background(DoggoTheme.card)
							.clipShape(Circle())
					}
					.disabled(viewModel.activeWalk == nil)
					Spacer()
					Text(statusTitle)
						.font(.system(size: 13, weight: .bold))
						.foregroundStyle(DoggoTheme.text)
						.padding(.horizontal, 16)
						.padding(.vertical, 9)
						.background(DoggoTheme.card)
						.clipShape(Capsule())
					Spacer()
					NavigationLink {
						WalkHistoryView(viewModel: viewModel)
					} label: {
						Image(systemName: "clock.arrow.circlepath")
							.font(.system(size: 18, weight: .semibold))
							.foregroundStyle(DoggoTheme.primary)
							.frame(width: 42, height: 42)
							.background(DoggoTheme.card)
							.clipShape(Circle())
					}
				}
				.padding(.horizontal, 13)
				.padding(.top, 50)
				Spacer()
			}

			bottomPanel
		}
		.task { await viewModel.load() }
		.onAppear {
			locationManager.requestWhenInUseAuthorization()
			centerMapOnUser()
		}
		.onChange(of: locationManager.coordinate?.latitude) { _, _ in
			centerMapOnUser()
		}
		.onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
			now = date
			sendLocationPointIfNeeded(at: date)
		}
	}

	private var walkMap: some View {
		ZStack {
			Map(position: $mapPosition) {
				if let coordinate = locationManager.coordinate {
					Annotation(viewModel.activeWalk == nil ? "Старт" : "Вы", coordinate: coordinate) {
						ZStack {
							Circle()
								.fill(.white)
								.frame(width: 28, height: 28)
							Circle()
								.fill(DoggoTheme.primary)
								.frame(width: 20, height: 20)
						}
					}
				}
			}
			.mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))

			if let errorMessage = locationManager.errorMessage {
				Text(errorMessage)
					.font(.system(size: 12))
					.foregroundStyle(.red)
					.padding(10)
					.background(DoggoTheme.card)
					.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
					.padding(.top, 106)
					.frame(maxHeight: .infinity, alignment: .top)
			}
		}
	}

	private var bottomPanel: some View {
		VStack(spacing: 19) {
			Capsule()
				.fill(DoggoTheme.divider)
				.frame(width: 42, height: 4)
				.padding(.top, 10)

			VStack(spacing: 5) {
				Text("ПРОДОЛЖИТЕЛЬНОСТЬ")
					.font(.system(size: 12, weight: .bold))
					.foregroundStyle(DoggoTheme.mutedText)
				Text(DoggoFormatters.duration(currentDurationSeconds))
					.font(.system(size: 43, weight: .heavy))
					.foregroundStyle(DoggoTheme.text)
			}

			HStack(spacing: 9) {
				WalkMetric(value: DoggoFormatters.distance(currentDistanceMeters), label: "дистанция")
				WalkMetric(value: currentPace, label: "мин/км")
				WalkMetric(value: "\(estimatedCalories)", label: "ккал")
			}

			HStack(spacing: 28) {
				RoundActionButton(systemName: "camera")
				Button {
					if viewModel.activeWalk == nil {
						locationManager.startUpdating()
						Task {
							await viewModel.start()
							if let coordinate = locationManager.coordinate {
								await viewModel.addPoint(coordinate)
								lastPointSentAt = Date()
							}
						}
					} else {
						Task {
							await viewModel.finish()
							locationManager.stopUpdating()
						}
					}
				} label: {
					Image(systemName: viewModel.activeWalk == nil ? "play.fill" : "stop.fill")
						.font(.system(size: 22, weight: .bold))
						.foregroundStyle(.white)
						.frame(width: 70, height: 70)
						.background(Color(red: 0.69, green: 0.25, blue: 0.22))
						.clipShape(Circle())
						.shadow(color: .black.opacity(0.15), radius: 14, y: 8)
				}
				.buttonStyle(.plain)
				RoundActionButton(systemName: "pause")
			}
			.padding(.bottom, 36)
		}
		.frame(maxWidth: .infinity)
		.background(DoggoTheme.background)
		.clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
	}

	private var statusTitle: String {
		viewModel.activeWalk == nil ? "Готово · \(safePetName)" : "●  Запись · \(safePetName)"
	}

	private var safePetName: String {
		let trimmed = pet.name.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed.count < 2 {
			return "питомец"
		}
		return trimmed
	}

	private var currentDistanceMeters: Double {
		viewModel.activeWalk?.distanceMeters ?? 0
	}

	private var currentDurationSeconds: Int64 {
		guard let activeWalk = viewModel.activeWalk else {
			return 0
		}
		return max(activeWalk.durationSeconds, Int64(now.timeIntervalSince(activeWalk.startedAt)))
	}

	private var currentPace: String {
		guard currentDistanceMeters >= 100, currentDurationSeconds > 0 else {
			return "—"
		}
		let secondsPerKm = Double(currentDurationSeconds) / (currentDistanceMeters / 1000)
		return "\(Int(secondsPerKm) / 60):\(String(format: "%02d", Int(secondsPerKm) % 60))"
	}

	private var estimatedCalories: Int {
		Int((currentDistanceMeters / 1000 * 55).rounded())
	}

	private func centerMapOnUser() {
		guard let coordinate = locationManager.coordinate else {
			return
		}
		mapPosition = .region(
			MKCoordinateRegion(
				center: coordinate,
				span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
			)
		)
	}

	private func sendLocationPointIfNeeded(at date: Date) {
		guard
			viewModel.activeWalk != nil,
			let coordinate = locationManager.coordinate
		else {
			return
		}
		if let lastPointSentAt, date.timeIntervalSince(lastPointSentAt) < 10 {
			return
		}
		lastPointSentAt = date
		Task {
			await viewModel.addPoint(coordinate)
		}
	}
}

private struct WalkHistoryView: View {
	@Bindable var viewModel: WalksViewModel
	@Environment(\.dismiss) private var dismiss
	@State private var segment = 0

	var body: some View {
		DoggoScreen {
			ScrollView(showsIndicators: false) {
				VStack(alignment: .leading, spacing: 14) {
					HStack {
						Button("‹ Назад") { dismiss() }
							.font(.system(size: 14))
							.foregroundStyle(DoggoTheme.primary)
						Spacer()
						Text("История")
							.font(.system(size: 16, weight: .bold))
							.foregroundStyle(DoggoTheme.text)
						Spacer()
						Image(systemName: "line.3.horizontal.decrease")
							.foregroundStyle(DoggoTheme.primary)
					}
					.padding(.top, 31)

					weeklyCard
					DoggoSegmentedPicker(items: ["Неделя", "Месяц", "Год", "Всё"], selection: $segment)

					Text("ПРОГУЛКИ")
						.font(.system(size: 12, weight: .bold))
						.foregroundStyle(DoggoTheme.secondaryText)

					DoggoCard {
						VStack(spacing: 0) {
							if viewModel.walks.isEmpty {
								Text("История пока пустая")
									.font(.system(size: 13))
									.foregroundStyle(DoggoTheme.secondaryText)
									.frame(maxWidth: .infinity, minHeight: 54)
							}
							ForEach(displayWalks) { walk in
								WalkHistoryRow(walk: walk)
								if walk.id != displayWalks.last?.id {
									Divider().background(DoggoTheme.divider)
								}
							}
						}
					}
				}
				.padding(.horizontal, 15)
				.padding(.bottom, 28)
			}
		}
		.task { await viewModel.load() }
	}

	private var displayWalks: [WalkResponse] {
		Array(viewModel.walks.prefix(6))
	}

	private var weeklyCard: some View {
		DoggoCard {
			VStack(alignment: .leading, spacing: 10) {
				HStack(alignment: .top) {
					VStack(alignment: .leading, spacing: 1) {
						Text("На этой неделе")
							.font(.system(size: 12))
							.foregroundStyle(DoggoTheme.secondaryText)
						Text(DoggoFormatters.distance(viewModel.stats?.totalDistanceMeters ?? 0))
							.font(.system(size: 30, weight: .heavy))
							.foregroundStyle(DoggoTheme.text)
						Text("по этому питомцу")
							.font(.system(size: 12))
							.foregroundStyle(DoggoTheme.secondaryText)
					}
					Spacer()
					VStack(alignment: .trailing, spacing: 1) {
						Text("Прогулок")
							.font(.system(size: 12))
							.foregroundStyle(DoggoTheme.secondaryText)
						Text("\(viewModel.stats?.totalWalks ?? 0)")
							.font(.system(size: 30, weight: .heavy))
							.foregroundStyle(DoggoTheme.text)
						Text("за всё время")
							.font(.system(size: 12))
							.foregroundStyle(DoggoTheme.secondaryText)
					}
				}

				HStack(alignment: .bottom, spacing: 14) {
					ForEach(Array(["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"].enumerated()), id: \.offset) { index, day in
						VStack(spacing: 6) {
							RoundedRectangle(cornerRadius: 5, style: .continuous)
								.fill(index == 4 ? DoggoTheme.primary : DoggoTheme.softGreen)
								.frame(width: 31, height: barHeight(index))
							Text(day)
								.font(.system(size: 11, weight: index == 4 ? .bold : .regular))
								.foregroundStyle(index == 4 ? DoggoTheme.text : DoggoTheme.secondaryText)
						}
					}
				}
				.frame(maxWidth: .infinity)
			}
			.padding(15)
		}
	}

	private func barHeight(_ index: Int) -> CGFloat {
		let base: [CGFloat] = [20, 28, 22, 34, 42, 24, 18]
		guard !viewModel.walks.isEmpty else {
			return 12
		}
		return base[index]
	}
}

private struct WalkMetric: View {
	let value: String
	let label: String

	var body: some View {
		DoggoCard {
			VStack(spacing: 1) {
				Text(value)
					.font(.system(size: 22, weight: .heavy))
					.foregroundStyle(DoggoTheme.text)
				Text(label)
					.font(.system(size: 10))
					.foregroundStyle(DoggoTheme.secondaryText)
			}
			.frame(maxWidth: .infinity)
			.frame(height: 57)
		}
	}
}

private struct WalkMapBackground: View {
	var body: some View {
		ZStack {
			DoggoTheme.background
			Capsule().fill(DoggoTheme.softGreen.opacity(0.55)).frame(width: 230, height: 90).offset(x: -92, y: 30).rotationEffect(.degrees(-12))
			Capsule().fill(DoggoTheme.softGreen.opacity(0.55)).frame(width: 200, height: 70).offset(x: 120, y: -95).rotationEffect(.degrees(-8))
			Capsule().fill(Color.blue.opacity(0.12)).frame(width: 160, height: 52).offset(x: 125, y: 190)
			ForEach([-120, -28, 70, 145], id: \.self) { x in
				Rectangle().fill(.white).frame(width: 8, height: 760).offset(x: CGFloat(x)).rotationEffect(.degrees(-7))
			}
			ForEach([-180, -72, 42, 150], id: \.self) { y in
				Rectangle().fill(.white).frame(width: 430, height: 8).offset(y: CGFloat(y)).rotationEffect(.degrees(-5))
			}
		}
	}
}

private struct RoundActionButton: View {
	let systemName: String

	var body: some View {
		Image(systemName: systemName)
			.font(.system(size: 16, weight: .semibold))
			.foregroundStyle(DoggoTheme.text)
			.frame(width: 54, height: 54)
			.background(DoggoTheme.card)
			.clipShape(Circle())
	}
}

private struct WalkHistoryRow: View {
	let walk: WalkResponse

	var body: some View {
		HStack(spacing: 11) {
			DoggoIconBubble(systemName: "pawprint.fill", color: DoggoTheme.softGreen, size: 42)
			VStack(alignment: .leading, spacing: 2) {
				Text("\(walk.petName) · \(walk.distanceMeters / 1000, specifier: "%.1f") км")
					.font(.system(size: 14, weight: .bold))
					.foregroundStyle(DoggoTheme.text)
				Text("\(DateFormatter.doggoDayMonth.string(from: walk.startedAt)) · \(DateFormatter.doggoTime.string(from: walk.startedAt))")
					.font(.system(size: 12))
					.foregroundStyle(DoggoTheme.secondaryText)
			}
			Spacer()
			Text("\(max(1, walk.durationSeconds / 60)) мин")
				.font(.system(size: 12, weight: .bold))
				.foregroundStyle(DoggoTheme.secondaryText)
				.padding(.horizontal, 10)
				.padding(.vertical, 7)
				.background(DoggoTheme.divider.opacity(0.55))
				.clipShape(Capsule())
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 9)
	}
}
