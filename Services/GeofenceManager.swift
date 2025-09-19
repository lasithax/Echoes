import Foundation
import CoreLocation

/// Sets up region monitoring around saved memory locations and posts a local notification when the user enters one of those areas.
final class GeofenceManager: NSObject, ObservableObject {
	private let locationManager = CLLocationManager()
	private let notifications: NotificationsManager
	
	@Published var monitoredRegionIdentifiers: [String] = []
	@Published var errorMessage: String?
	
	init(notifications: NotificationsManager) {
		self.notifications = notifications
		super.init()
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
	}
	
	/// Requests "Always" permission.
	func requestAlwaysAuthorization() {
		if locationManager.authorizationStatus == .notDetermined {
			print("GEF DEBUG: Requesting Always location authorization")
			locationManager.requestAlwaysAuthorization()
		}
	}
	
	/// Uses a general radius to work on simulator and in low accuracy conditions.
	func syncRegions(memories: [EchoMemory]) {
		guard CLLocationManager.locationServicesEnabled() else {
			print("GEF DEBUG: Location services disabled")
			return
		}
		guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
			print("GEF DEBUG: Region monitoring not available")
			return
		}
		let auth = locationManager.authorizationStatus
		print("GEF DEBUG: Authorization status = \(auth.rawValue)")
		
		// Remove all old regions
		for region in locationManager.monitoredRegions {
			locationManager.stopMonitoring(for: region)
		}
		monitoredRegionIdentifiers.removeAll()
		
		var started = 0
		for memory in memories {
			let lat = memory.latitude
			let lon = memory.longitude
			guard lat.isFinite, lon.isFinite else { continue }
			let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
			guard CLLocationCoordinate2DIsValid(center) else { continue }
			
			// Slightly larger radius to help simulator and low accuracy conditions
			let region = CLCircularRegion(center: center, radius: 150, identifier: memory.id?.uuidString ?? UUID().uuidString)
			region.notifyOnEntry = true
			region.notifyOnExit = false
			
			locationManager.startMonitoring(for: region)
			locationManager.requestState(for: region) // Ask for current state
			monitoredRegionIdentifiers.append(region.identifier)
			started += 1
		}
		print("GEF DEBUG: Monitoring \(started) regions")
	}
}

extension GeofenceManager: CLLocationManagerDelegate {
	func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
		print("GEF DEBUG: didStartMonitoringFor id=\(region.identifier)")
	}
	
	func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
		let stateStr: String
		switch state {
		case .inside: stateStr = "inside"
		case .outside: stateStr = "outside"
		case .unknown: stateStr = "unknown"
		@unknown default: stateStr = "unknown*"
		}
		print("GEF DEBUG: didDetermineState=\(stateStr) for id=\(region.identifier)")
	}
	
	func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
		print("GEF DEBUG: didEnterRegion id=\(region.identifier)")
		guard let circular = region as? CLCircularRegion else { return }
		let title = "Echo Unlocked"
		let body = "You've returned to a place with a memory. Tap to revisit it."
		notifications.scheduleMemoryUnlockedNotification(id: circular.identifier, title: title, body: body)
	}
	
	func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
		DispatchQueue.main.async {
			self.errorMessage = "Monitoring failed: \(error.localizedDescription)"
		}
		print("GEF DEBUG: monitoringDidFailFor id=\(region?.identifier ?? "nil") error=\(error.localizedDescription)")
	}
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		print("GEF DEBUG: didChangeAuthorization to \(status.rawValue)")
	}
}
