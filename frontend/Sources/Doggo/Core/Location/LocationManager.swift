import CoreLocation
import Foundation
import Observation

@MainActor
@Observable
public final class LocationManager: NSObject, CLLocationManagerDelegate {
	public private(set) var coordinate: CLLocationCoordinate2D?
	public private(set) var authorizationStatus: CLAuthorizationStatus
	public private(set) var errorMessage: String?

	private let manager = CLLocationManager()

	public override init() {
		self.authorizationStatus = manager.authorizationStatus
		super.init()
		manager.delegate = self
		manager.desiredAccuracy = kCLLocationAccuracyBest
		manager.distanceFilter = 10
	}

	public func requestWhenInUseAuthorization() {
		errorMessage = nil
		switch authorizationStatus {
		case .notDetermined:
			manager.requestWhenInUseAuthorization()
		case .authorizedAlways:
			manager.startUpdatingLocation()
			manager.requestLocation()
		#if os(iOS)
		case .authorizedWhenInUse:
			manager.startUpdatingLocation()
			manager.requestLocation()
		#endif
		case .denied, .restricted:
			errorMessage = "Геолокация выключена. Разреши доступ в настройках iOS."
		@unknown default:
			errorMessage = "Не удалось определить статус геолокации."
		}
	}

	public func startUpdating() {
		requestWhenInUseAuthorization()
	}

	public func stopUpdating() {
		manager.stopUpdatingLocation()
	}

	public nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		let status = manager.authorizationStatus
		Task { @MainActor in
			authorizationStatus = status
			if isAuthorized(authorizationStatus) {
				self.manager.startUpdatingLocation()
				self.manager.requestLocation()
			}
		}
	}

	public nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let location = locations.last else {
			return
		}
		Task { @MainActor in
			coordinate = location.coordinate
			errorMessage = nil
		}
	}

	public nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		Task { @MainActor in
			errorMessage = error.localizedDescription
		}
	}

	private func isAuthorized(_ status: CLAuthorizationStatus) -> Bool {
		if status == .authorizedAlways {
			return true
		}
		#if os(iOS)
		return status == .authorizedWhenInUse
		#else
		return false
		#endif
	}
}
