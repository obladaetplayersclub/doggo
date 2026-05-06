import CoreLocation
import Foundation
import Observation

@MainActor
@Observable
public final class WalksViewModel {
	public var walks: [WalkResponse] = []
	public var stats: WalkStatsResponse?
	public var activeWalk: WalkResponse?
	public var isLoading = false
	public var errorMessage: String?

	private let apiClient: APIClient
	private let pet: PetResponse

	public init(apiClient: APIClient, pet: PetResponse) {
		self.apiClient = apiClient
		self.pet = pet
	}

	public func load() async {
		isLoading = true
		errorMessage = nil
		defer { isLoading = false }

		do {
			walks = try await apiClient.get("/api/pets/\(pet.id.uuidString)/walks")
			stats = try await apiClient.get("/api/pets/\(pet.id.uuidString)/walks/stats")
			activeWalk = walks.first { $0.status == .active }
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	public func start() async {
		do {
			activeWalk = try await apiClient.post(
				"/api/pets/\(pet.id.uuidString)/walks",
				body: StartWalkRequest(startedAt: Date())
			)
			await load()
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	public func addPoint(_ coordinate: CLLocationCoordinate2D) async {
		guard let activeWalk else {
			return
		}
		do {
			self.activeWalk = try await apiClient.post(
				"/api/walks/\(activeWalk.id.uuidString)/points",
				body: AddWalkPointsRequest(points: [
					WalkPointRequest(latitude: coordinate.latitude, longitude: coordinate.longitude, recordedAt: Date())
				])
			)
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	public func finish() async {
		guard let activeWalk else {
			return
		}
		do {
			let _: WalkResponse = try await apiClient.post(
				"/api/walks/\(activeWalk.id.uuidString)/finish",
				body: FinishWalkRequest(endedAt: Date())
			)
			self.activeWalk = nil
			await load()
		} catch {
			errorMessage = error.localizedDescription
		}
	}
}
