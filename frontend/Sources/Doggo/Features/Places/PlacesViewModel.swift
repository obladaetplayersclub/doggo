import Foundation
import CoreLocation
import Observation

public enum PlaceSort: String, CaseIterable, Identifiable {
	case distance
	case rating

	public var id: String { rawValue }

	public var displayName: String {
		switch self {
		case .distance: "По расстоянию"
		case .rating: "По рейтингу"
		}
	}
}

@MainActor
@Observable
public final class PlacesViewModel {
	public var places: [PlaceSummaryResponse] = []
	public var selectedPlace: PlaceDetailsResponse?
	public var searchText = ""
	public var selectedCategory: PlaceCategory?
	public var selectedDistrict: String?
	public var selectedMetro: String?
	public var selectedSort: PlaceSort = .rating
	public var isLoading = false
	public var errorMessage: String?

	public let districtOptions = [
		"Тверской",
		"Пресненский",
		"Басманный",
		"Гагаринский",
		"Тимирязевский",
		"Сокольники"
	]

	public let metroOptions = [
		"Тверская",
		"Баррикадная",
		"Чистые пруды",
		"Цветной бульвар",
		"Ленинский проспект",
		"Верхние Лихоборы",
		"Сокольники",
		"Менделеевская"
	]

	private let apiClient: APIClient

	public init(apiClient: APIClient) {
		self.apiClient = apiClient
	}

	public func loadPlaces(coordinate: CLLocationCoordinate2D? = nil, radiusKm: Int? = nil) async {
		isLoading = true
		errorMessage = nil
		defer { isLoading = false }

		do {
			var queryItems: [URLQueryItem] = []
			if !searchText.isEmpty {
				queryItems.append(URLQueryItem(name: "query", value: searchText))
			}
			if let selectedCategory {
				queryItems.append(URLQueryItem(name: "category", value: selectedCategory.rawValue))
			}
			if let selectedDistrict {
				queryItems.append(URLQueryItem(name: "district", value: selectedDistrict))
			}
			if let selectedMetro {
				queryItems.append(URLQueryItem(name: "metro", value: selectedMetro))
			}
			if let coordinate {
				queryItems.append(URLQueryItem(name: "latitude", value: String(coordinate.latitude)))
				queryItems.append(URLQueryItem(name: "longitude", value: String(coordinate.longitude)))
			}
			if let radiusKm {
				queryItems.append(URLQueryItem(name: "radiusKm", value: String(radiusKm)))
			}
			queryItems.append(URLQueryItem(name: "sort", value: selectedSort.rawValue))
			places = try await apiClient.get("/api/places", queryItems: queryItems)
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	public func loadDetails(for place: PlaceSummaryResponse) async {
		do {
			selectedPlace = try await apiClient.get("/api/places/\(place.id.uuidString)")
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	public func submitReview(placeId: UUID, rating: Int, text: String) async {
		do {
			let _: ReviewResponse = try await apiClient.put(
				"/api/places/\(placeId.uuidString)/reviews/me",
				body: ReviewUpsertRequest(rating: rating, text: text)
			)
			if let selectedPlace, selectedPlace.id == placeId {
				let details: PlaceDetailsResponse = try await apiClient.get("/api/places/\(placeId.uuidString)")
				self.selectedPlace = details
			}
			await loadPlaces()
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	public func deleteMyReview(placeId: UUID) async {
		do {
			try await apiClient.delete("/api/places/\(placeId.uuidString)/reviews/me")
			await refreshDetails(placeId: placeId)
			await loadPlaces()
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	public func complain(placeId: UUID, reviewId: UUID, reason: String = "Некорректный отзыв") async {
		do {
			let _: ReviewResponse = try await apiClient.post(
				"/api/places/\(placeId.uuidString)/reviews/\(reviewId.uuidString)/complaints",
				body: ReviewComplaintRequest(reason: reason)
			)
			await refreshDetails(placeId: placeId)
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	private func refreshDetails(placeId: UUID) async {
		do {
			let details: PlaceDetailsResponse = try await apiClient.get("/api/places/\(placeId.uuidString)")
			selectedPlace = details
		} catch {
			errorMessage = error.localizedDescription
		}
	}
}
