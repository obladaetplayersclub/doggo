import SwiftUI
import MapKit

public struct PlacesView: View {
	@Bindable private var viewModel: PlacesViewModel
	@Bindable private var locationManager: LocationManager
	private let currentUserId: UUID?
	@State private var radiusSelection = 1
	@State private var showDistrictPicker = false
	@State private var showMetroPicker = false
	@State private var showSortPicker = false
	@State private var mapPosition: MapCameraPosition = .region(
		MKCoordinateRegion(
			center: CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6173),
			span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
		)
	)

	public init(viewModel: PlacesViewModel, locationManager: LocationManager, currentUserId: UUID?) {
		self.viewModel = viewModel
		self.locationManager = locationManager
		self.currentUserId = currentUserId
	}

	public var body: some View {
		DoggoScreen {
			ScrollView(showsIndicators: false) {
				VStack(spacing: 0) {
					mapHeader
					filters
					placesList
				}
				.padding(.bottom, 86)
			}
		}
		.task { await reloadPlaces() }
		.refreshable { await reloadPlaces() }
		.onChange(of: locationManager.coordinate?.latitude) { _, _ in
			centerMapOnUser()
			Task { await reloadPlaces() }
		}
	}

	private var mapHeader: some View {
		ZStack(alignment: .top) {
			Map(position: $mapPosition) {
				ForEach(viewModel.places) { place in
					Marker(
						place.name,
						systemImage: place.category.mapIcon,
						coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
					)
					.tint(DoggoTheme.primary)
				}
				if let coordinate = locationManager.coordinate {
					Annotation("Вы", coordinate: coordinate) {
						ZStack {
							Circle()
								.fill(.white)
								.frame(width: 24, height: 24)
							Circle()
								.fill(DoggoTheme.primary)
								.frame(width: 16, height: 16)
						}
					}
				}
			}
			.mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
				.frame(height: 270)
				.clipShape(RoundedRectangle(cornerRadius: 0))

			VStack(spacing: 0) {
				HStack {
					Image(systemName: "magnifyingglass")
						.foregroundStyle(DoggoTheme.secondaryText)
					TextField("Поиск мест и услуг", text: $viewModel.searchText)
						.font(.system(size: 13))
						.onSubmit { Task { await reloadPlaces() } }
					Button {
						Task { await reloadPlaces() }
					} label: {
						Image(systemName: "line.3.horizontal.decrease")
							.foregroundStyle(DoggoTheme.primary)
					}
				}
				.padding(.horizontal, 12)
				.frame(height: 42)
				.background(DoggoTheme.card)
				.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
				.padding(.horizontal, 9)
				.padding(.top, 44)

				Spacer()
			}

			Button {
				locationManager.requestWhenInUseAuthorization()
				centerMapOnUser()
				Task { await reloadPlaces() }
			} label: {
				Image(systemName: "location.fill")
					.font(.system(size: 17, weight: .bold))
					.foregroundStyle(DoggoTheme.primary)
					.frame(width: 42, height: 42)
					.background(DoggoTheme.card)
					.clipShape(Circle())
			}
			.buttonStyle(.plain)
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
			.padding(.trailing, 14)
			.padding(.bottom, 16)
		}
	}

	private var filters: some View {
		VStack(alignment: .leading, spacing: 10) {
			ScrollView(.horizontal, showsIndicators: false) {
				HStack(spacing: 8) {
					Button {
						viewModel.selectedCategory = nil
						Task { await reloadPlaces() }
					} label: {
						DoggoChip(title: "Все", isSelected: viewModel.selectedCategory == nil)
					}
					ForEach(PlaceCategory.allCases) { category in
						Button {
							viewModel.selectedCategory = category
							Task { await reloadPlaces() }
						} label: {
							DoggoChip(title: category.displayName, isSelected: viewModel.selectedCategory == category)
						}
					}
				}
			}

			HStack(spacing: 16) {
				Text("РАДИУС")
					.font(.system(size: 10, weight: .bold))
					.foregroundStyle(DoggoTheme.secondaryText)
				ForEach(["1 км", "3 км", "5 км", "10 км"].indices, id: \.self) { index in
					Button {
						radiusSelection = index
						Task { await reloadPlaces() }
					} label: {
						Text(["1 км", "3 км", "5 км", "10 км"][index])
							.font(.system(size: 11, weight: radiusSelection == index ? .bold : .regular))
							.foregroundStyle(radiusSelection == index ? DoggoTheme.primary : DoggoTheme.secondaryText)
							.padding(.horizontal, 9)
							.padding(.vertical, 5)
							.background(radiusSelection == index ? DoggoTheme.softGreen : .clear)
							.clipShape(Capsule())
					}
					.buttonStyle(.plain)
				}
			}

			HStack(spacing: 8) {
				Button {
					showDistrictPicker = true
				} label: {
					DoggoChip(
						title: viewModel.selectedDistrict.map { "⌾ \($0)" } ?? "⌾ Район",
						isSelected: viewModel.selectedDistrict != nil
					)
				}
				.buttonStyle(.plain)

				Button {
					showMetroPicker = true
				} label: {
					DoggoChip(
						title: viewModel.selectedMetro.map { "Ⓜ \($0)" } ?? "Ⓜ Метро",
						isSelected: viewModel.selectedMetro != nil
					)
				}
				.buttonStyle(.plain)

				Button {
					showSortPicker = true
				} label: {
					DoggoChip(title: "⇅ \(viewModel.selectedSort.displayName)", isSelected: true)
				}
				.buttonStyle(.plain)
			}
		}
		.padding(.horizontal, 8)
		.padding(.top, 10)
		.confirmationDialog("Район", isPresented: $showDistrictPicker, titleVisibility: .visible) {
			Button("Все районы") {
				viewModel.selectedDistrict = nil
				Task { await reloadPlaces() }
			}
			ForEach(viewModel.districtOptions, id: \.self) { district in
				Button(district) {
					viewModel.selectedDistrict = district
					Task { await reloadPlaces() }
				}
			}
		}
		.confirmationDialog("Метро", isPresented: $showMetroPicker, titleVisibility: .visible) {
			Button("Все станции") {
				viewModel.selectedMetro = nil
				Task { await reloadPlaces() }
			}
			ForEach(viewModel.metroOptions, id: \.self) { metro in
				Button(metro) {
					viewModel.selectedMetro = metro
					Task { await reloadPlaces() }
				}
			}
		}
		.confirmationDialog("Сортировка", isPresented: $showSortPicker, titleVisibility: .visible) {
			ForEach(PlaceSort.allCases) { sort in
				Button(sort.displayName) {
					viewModel.selectedSort = sort
					Task { await reloadPlaces() }
				}
			}
		}
	}

	private var selectedRadiusKm: Int {
		[1, 3, 5, 10][radiusSelection]
	}

	private func reloadPlaces() async {
		await viewModel.loadPlaces(coordinate: locationManager.coordinate, radiusKm: selectedRadiusKm)
	}

	private func centerMapOnUser() {
		guard let coordinate = locationManager.coordinate else {
			return
		}
		mapPosition = .region(
			MKCoordinateRegion(
				center: coordinate,
				span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
			)
		)
	}

	private var placesList: some View {
		VStack(spacing: 8) {
			if viewModel.places.isEmpty && !viewModel.isLoading {
				DoggoCard {
					EmptyStateView(title: "Места не найдены", systemImage: "map")
						.padding(.vertical, 20)
				}
			}

			ForEach(viewModel.places) { place in
				NavigationLink {
					PlaceDetailsView(viewModel: viewModel, place: place, currentUserId: currentUserId)
				} label: {
					PlaceRow(place: place)
				}
				.buttonStyle(.plain)
			}
		}
		.padding(.horizontal, 9)
		.padding(.top, 11)
	}
}

private struct PlaceRow: View {
	let place: PlaceSummaryResponse

	var body: some View {
		DoggoCard {
			HStack(spacing: 11) {
				DiagonalPlaceholder()
					.frame(width: 54, height: 54)
					.clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
				VStack(alignment: .leading, spacing: 4) {
					Text(place.name)
						.font(.system(size: 14, weight: .bold))
						.foregroundStyle(DoggoTheme.text)
					Text(place.category.displayName + distanceText)
						.font(.system(size: 11))
						.foregroundStyle(DoggoTheme.secondaryText)
					HStack(spacing: 8) {
						Text(ratingText)
							.foregroundStyle(.orange)
						DoggoChip(title: "без поводка")
						DoggoChip(title: "вода")
					}
					.font(.system(size: 10))
				}
				Spacer()
			}
			.padding(9)
		}
	}

	private var distanceText: String {
		guard let meters = place.distanceMeters else {
			return ""
		}
		return " · \(DoggoFormatters.distance(meters))"
	}

	private var ratingText: String {
		place.reviewCount == 0 ? "Нет отзывов" : "★ \(String(format: "%.1f", place.averageRating)) · \(place.reviewCount)"
	}
}

struct PlaceDetailsView: View {
	@Bindable var viewModel: PlacesViewModel
	let place: PlaceSummaryResponse
	let currentUserId: UUID?

	var body: some View {
		DoggoScreen {
			ScrollView(showsIndicators: false) {
				VStack(spacing: 0) {
					hero
					detailsCard
				}
				.padding(.bottom, 24)
			}
		}
		.task { await viewModel.loadDetails(for: place) }
	}

	private var hero: some View {
		ZStack(alignment: .top) {
			DiagonalPlaceholder()
				.frame(height: 230)
			HStack {
				CircleButton(systemName: "chevron.left")
				Spacer()
				CircleButton(systemName: "heart")
			}
			.padding(.horizontal, 10)
			.padding(.top, 46)
		}
	}

	private var detailsCard: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack(alignment: .top) {
				VStack(alignment: .leading, spacing: 3) {
					Text(place.name)
						.font(.system(size: 20, weight: .bold))
						.foregroundStyle(DoggoTheme.text)
					Text("\(place.category.displayName) · открыто круглосуточно")
						.font(.system(size: 12))
						.foregroundStyle(DoggoTheme.secondaryText)
				}
				Spacer()
				Text(place.reviewCount == 0 ? "Нет отзывов" : "★ \(String(format: "%.1f", place.averageRating)) · \(place.reviewCount)")
					.font(.system(size: 11, weight: .bold))
					.foregroundStyle(DoggoTheme.primary)
					.padding(.horizontal, 10)
					.padding(.vertical, 6)
					.background(DoggoTheme.softGreen)
					.clipShape(Capsule())
			}

			HStack {
				DoggoChip(title: "можно без поводка")
				DoggoChip(title: "миски с водой")
				DoggoChip(title: "площадка")
			}

			VStack(spacing: 0) {
				PlaceFactRow(icon: "mappin", title: place.address)
				PlaceFactRow(icon: "figure.walk", title: place.distanceMeters.map { "До места · \(DoggoFormatters.distance($0))" } ?? "Расстояние появится при геопозиции")
				PlaceFactRow(icon: "clock", title: "Открыто · круглосуточно")
			}
			.background(DoggoTheme.card)
			.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

			reviews

			NavigationLink {
				ReviewCreateView(viewModel: viewModel, place: place)
			} label: {
				Label("Оставить отзыв", systemImage: "pencil")
					.font(.system(size: 15, weight: .bold))
					.foregroundStyle(.white)
					.frame(maxWidth: .infinity)
					.frame(height: 48)
					.background(DoggoTheme.primary)
					.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
			}
			.buttonStyle(.plain)
		}
		.padding(14)
		.background(DoggoTheme.background)
		.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
		.offset(y: -18)
	}

	private var reviews: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack {
				Text("Отзывы")
					.font(.system(size: 15, weight: .bold))
					.foregroundStyle(DoggoTheme.text)
				Spacer()
				Text("Все \(viewModel.selectedPlace?.reviewCount ?? place.reviewCount)")
					.font(.system(size: 11))
					.foregroundStyle(DoggoTheme.secondaryText)
			}

			let reviews = viewModel.selectedPlace?.reviews ?? []
			if !reviews.isEmpty {
				ForEach(reviews) { review in
					let isOwnReview = currentUserId.map { $0 == review.authorId } ?? false
					DoggoCard {
						VStack(alignment: .leading, spacing: 8) {
							HStack(alignment: .top, spacing: 10) {
								DoggoIconBubble(systemName: "person.fill", color: DoggoTheme.softGreen, size: 36)
								VStack(alignment: .leading, spacing: 3) {
									HStack {
										Text(review.authorDisplayName)
											.font(.system(size: 13, weight: .bold))
										Spacer()
										Text(String(repeating: "★", count: review.rating))
											.font(.system(size: 10))
											.foregroundStyle(.orange)
									}
									Text(review.text)
										.font(.system(size: 12))
										.foregroundStyle(DoggoTheme.secondaryText)
										.lineLimit(3)
								}
							}
							HStack {
								if !isOwnReview {
									Button("Пожаловаться") {
										Task { await viewModel.complain(placeId: place.id, reviewId: review.id) }
									}
									.font(.system(size: 12, weight: .semibold))
									.foregroundStyle(DoggoTheme.secondaryText)
								}
								Spacer()
								if isOwnReview {
									Button("Удалить мой отзыв", role: .destructive) {
										Task { await viewModel.deleteMyReview(placeId: place.id) }
									}
									.font(.system(size: 12, weight: .semibold))
								}
							}
						}
						.padding(10)
					}
				}
			} else {
				DoggoCard {
					Text("Отзывов пока нет. Будь первым, кто расскажет о месте.")
						.font(.system(size: 12))
						.foregroundStyle(DoggoTheme.secondaryText)
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(12)
				}
			}
		}
	}
}

private struct ReviewCreateView: View {
	@Bindable var viewModel: PlacesViewModel
	let place: PlaceSummaryResponse
	@Environment(\.dismiss) private var dismiss
	@State private var rating = 4
	@State private var text = ""
	@State private var validationMessage: String?

	var body: some View {
		DoggoScreen {
			ScrollView(showsIndicators: false) {
				VStack(alignment: .leading, spacing: 14) {
					HStack {
						Button("‹ Назад") { dismiss() }
							.font(.system(size: 14))
							.foregroundStyle(DoggoTheme.primary)
						Spacer()
						Text("Отзыв")
							.font(.system(size: 15, weight: .bold))
							.foregroundStyle(DoggoTheme.text)
						Spacer()
						Button("Опубл.") {
							guard validate() else { return }
							Task {
								await viewModel.submitReview(placeId: place.id, rating: rating, text: text.trimmingCharacters(in: .whitespacesAndNewlines))
								dismiss()
							}
						}
						.font(.system(size: 14, weight: .semibold))
						.foregroundStyle(DoggoTheme.primary)
						.disabled(!canPublish)
					}
					.padding(.top, 31)

					DoggoCard {
						HStack(spacing: 11) {
							DiagonalPlaceholder()
								.frame(width: 46, height: 46)
								.clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
							VStack(alignment: .leading, spacing: 3) {
								Text(place.name)
									.font(.system(size: 13, weight: .bold))
								Text(place.address)
									.font(.system(size: 11))
									.foregroundStyle(DoggoTheme.secondaryText)
							}
							Spacer()
						}
						.padding(9)
					}

					Text("Как тебе тут понравилось?")
						.font(.system(size: 12))
						.foregroundStyle(DoggoTheme.secondaryText)
						.frame(maxWidth: .infinity)
					HStack(spacing: 12) {
						ForEach(1...5, id: \.self) { value in
							Button {
								rating = value
							} label: {
								Image(systemName: value <= rating ? "star.fill" : "star")
									.font(.system(size: 25))
									.foregroundStyle(value <= rating ? .orange : DoggoTheme.border)
							}
						}
					}
					.frame(maxWidth: .infinity)
					Text(rating >= 4 ? "Хорошо" : "Нормально")
						.font(.system(size: 12))
						.foregroundStyle(DoggoTheme.secondaryText)
						.frame(maxWidth: .infinity)

					VStack(alignment: .leading, spacing: 8) {
						Text("Что отмечаешь?")
							.font(.system(size: 12))
							.foregroundStyle(DoggoTheme.secondaryText)
						FlowTags(tags: ["без поводка", "чисто", "есть вода", "площадка", "много людей", "дорого", "дружелюбно"])
					}

					VStack(alignment: .leading, spacing: 6) {
						HStack {
							Text("Подробнее")
							Spacer()
							Text("\(text.count) / 500")
						}
						.font(.system(size: 11))
						.foregroundStyle(DoggoTheme.secondaryText)
						TextField("Поделись впечатлениями", text: $text, axis: .vertical)
							.font(.system(size: 13))
							.lineLimit(5...7)
							.padding(12)
							.background(DoggoTheme.card)
							.clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
						if let validationMessage {
							Text(validationMessage)
								.font(.system(size: 12))
								.foregroundStyle(.red)
						}
					}

					HStack(spacing: 8) {
						DiagonalPlaceholder()
						DiagonalPlaceholder()
						ZStack {
							RoundedRectangle(cornerRadius: 9, style: .continuous)
								.stroke(DoggoTheme.border, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
							Image(systemName: "plus")
								.foregroundStyle(DoggoTheme.secondaryText)
						}
					}
					.frame(height: 56)
				}
				.padding(.horizontal, 13)
				.padding(.bottom, 28)
			}
		}
	}

	private var canPublish: Bool {
		text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10
	}

	private func validate() -> Bool {
		if text.trimmingCharacters(in: .whitespacesAndNewlines).count < 10 {
			validationMessage = "Отзыв должен быть не короче 10 символов."
			return false
		}
		validationMessage = nil
		return true
	}
}

private struct DoggoMapBackground: View {
	var body: some View {
		ZStack {
			DoggoTheme.background
			Capsule().fill(DoggoTheme.softGreen.opacity(0.55)).frame(width: 210, height: 78).offset(x: -74, y: 58).rotationEffect(.degrees(-10))
			Capsule().fill(DoggoTheme.softGreen.opacity(0.55)).frame(width: 190, height: 64).offset(x: 105, y: 6).rotationEffect(.degrees(-8))
			Capsule().fill(Color.blue.opacity(0.12)).frame(width: 170, height: 48).offset(x: 126, y: 130)
			ForEach([-110, -30, 60, 130], id: \.self) { x in
				Rectangle().fill(.white).frame(width: 8, height: 330).offset(x: CGFloat(x)).rotationEffect(.degrees(-7))
			}
			ForEach([-80, 10, 95], id: \.self) { y in
				Rectangle().fill(.white).frame(width: 390, height: 8).offset(y: CGFloat(y)).rotationEffect(.degrees(-5))
			}
		}
	}
}

private struct MapPin: View {
	let index: Int

	var body: some View {
		ZStack {
			Image(systemName: "mappin.circle.fill")
				.font(.system(size: 36))
				.foregroundStyle(DoggoTheme.primary)
			Image(systemName: ["cross.case.fill", "cup.and.saucer.fill", "pawprint.fill", "leaf.fill"][index % 4])
				.font(.system(size: 11))
				.foregroundStyle(.white)
				.offset(y: -2)
		}
	}
}

private struct DiagonalPlaceholder: View {
	var body: some View {
		ZStack {
			DoggoTheme.divider.opacity(0.55)
			Canvas { context, size in
				let path = Path { path in
					for offset in stride(from: -size.height, through: size.width, by: 12) {
						path.move(to: CGPoint(x: offset, y: size.height))
						path.addLine(to: CGPoint(x: offset + size.height, y: 0))
					}
				}
				context.stroke(path, with: .color(.white.opacity(0.35)), lineWidth: 4)
			}
		}
	}
}

private struct CircleButton: View {
	let systemName: String

	var body: some View {
		Image(systemName: systemName)
			.font(.system(size: 13, weight: .semibold))
			.foregroundStyle(DoggoTheme.text)
			.frame(width: 34, height: 34)
			.background(DoggoTheme.card)
			.clipShape(Circle())
	}
}

private struct PlaceFactRow: View {
	let icon: String
	let title: String

	var body: some View {
		HStack(spacing: 10) {
			Image(systemName: icon)
				.frame(width: 18)
				.foregroundStyle(DoggoTheme.primary)
			Text(title)
				.font(.system(size: 12))
				.foregroundStyle(DoggoTheme.text)
			Spacer()
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 11)
		.overlay(alignment: .bottom) {
			Divider().background(DoggoTheme.divider)
		}
	}
}

private struct FlowTags: View {
	let tags: [String]

	var body: some View {
		VStack(alignment: .leading, spacing: 7) {
			HStack {
				ForEach(tags.prefix(4), id: \.self) { tag in
					DoggoChip(title: tag, isSelected: tag.count % 2 == 0)
				}
			}
			HStack {
				ForEach(tags.dropFirst(4), id: \.self) { tag in
					DoggoChip(title: tag)
				}
			}
		}
	}
}
