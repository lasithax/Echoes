import Foundation
import CoreLocation
import SwiftUI

/// Fetching the user's current location and turn it into comparison friendly for the UI.
class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    override init() {
        super.init()
        print("DEBUG: LocationManager init")
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        
        // current system permission state
        authorizationStatus = locationManager.authorizationStatus
        print("DEBUG: Initial authorization status: \(authorizationStatus.rawValue)")
    }
    
    /// Asks for "When In Use" location permission.
    func requestLocationPermission() {
        print("DEBUG: requestLocationPermission called, status: \(authorizationStatus.rawValue)")
        
        switch authorizationStatus {
        case .notDetermined:
            print("DEBUG: Requesting location permission")
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("DEBUG: Location access denied")
            errorMessage = "Location access denied. Please enable in Settings."
        case .authorizedWhenInUse, .authorizedAlways:
            print("DEBUG: Location permission already granted")
            getCurrentLocation()
        @unknown default:
            print("DEBUG: Unknown location permission status")
            break
        }
    }
    
    /// Fetching the current location.
    func getCurrentLocation() {
        print("DEBUG: getCurrentLocation called")
        
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("DEBUG: Location not authorized, requesting permission")
            requestLocationPermission()
            return
        }
        
        print("DEBUG: Starting location updates")
        isLoading = true
        errorMessage = nil
        
        // Starting continuous updates
        locationManager.startUpdatingLocation()
        
        // Stop after getting location or timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            print("DEBUG: Location timeout reached")
            self.locationManager.stopUpdatingLocation()
            if self.location == nil && self.isLoading {
                self.isLoading = false
                self.errorMessage = "Location request timed out. Please try again."
                print("DEBUG: Location request timed out")
            }
        }
    }
    
    /// Turns raw coordinates into a readable string.
    func getLocationName(for location: CLLocation, completion: @escaping (String) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Geocoding error: \(error.localizedDescription)")
                    completion("Unknown Location")
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    completion("Unknown Location")
                    return
                }
                
                var locationName = ""
                
                if let name = placemark.name {
                    locationName = name
                } else if let thoroughfare = placemark.thoroughfare {
                    locationName = thoroughfare
                    if let subThoroughfare = placemark.subThoroughfare {
                        locationName = "\(subThoroughfare) \(locationName)"
                    }
                } else if let locality = placemark.locality {
                    locationName = locality
                } else if let administrativeArea = placemark.administrativeArea {
                    locationName = administrativeArea
                } else {
                    locationName = "Unknown Location"
                }
                
                // Add locality again if we have a street name but no city
                if let locality = placemark.locality, !locationName.contains(locality) {
                    locationName += ", \(locality)"
                }
                
                completion(locationName)
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("DEBUG: didUpdateLocations called with \(locations.count) locations")
        
        DispatchQueue.main.async {
            self.isLoading = false
            
            // Validate coordinates before accepting the result
            if let location = locations.last {
                print("DEBUG: Received location: \(location.coordinate)")
                
                if location.coordinate.latitude.isFinite,
                   location.coordinate.longitude.isFinite,
                   CLLocationCoordinate2DIsValid(location.coordinate) {
                    self.location = location
                    self.errorMessage = nil
                    print("DEBUG: Location is valid and set")
                } else {
                    self.errorMessage = "Invalid location coordinates received"
                    print("DEBUG: Invalid location coordinates")
                }
            } else {
                print("DEBUG: No location in array")
            }
            
            // Stop updating once we get a location
            manager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = "Failed to get location: \(error.localizedDescription)"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("DEBUG: didChangeAuthorization called with status: \(status.rawValue)")
        
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                print("DEBUG: Location authorized, getting current location")
                // The caller will handle getting location after permission is granted
                self.errorMessage = nil
            case .denied, .restricted:
                print("DEBUG: Location access denied")
                self.errorMessage = "Location access denied. Please enable in Settings."
                self.isLoading = false
            case .notDetermined:
                print("DEBUG: Location permission not determined")
                self.isLoading = false
                break
            @unknown default:
                print("DEBUG: Unknown location authorization status")
                self.isLoading = false
                break
            }
        }
    }
}

// Custom location structure for UI
struct CustomLocation: Identifiable, Codable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    let address: String?
    
    var coordinate: CLLocationCoordinate2D {
        let lat = latitude.isFinite ? latitude : 0.0
        let lon = longitude.isFinite ? longitude : 0.0
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    var clLocation: CLLocation {
        let lat = latitude.isFinite ? latitude : 0.0
        let lon = longitude.isFinite ? longitude : 0.0
        return CLLocation(latitude: lat, longitude: lon)
    }
    
    init(name: String, latitude: Double, longitude: Double, address: String? = nil) {
        self.name = name
        // Ensuring coordinates are valid
        self.latitude = latitude.isFinite ? latitude : 0.0
        self.longitude = longitude.isFinite ? longitude : 0.0
        self.address = address
    }
    
    init(name: String, location: CLLocation, address: String? = nil) {
        self.name = name
        // Ensuring coordinates are valid
        self.latitude = location.coordinate.latitude.isFinite ? location.coordinate.latitude : 0.0
        self.longitude = location.coordinate.longitude.isFinite ? location.coordinate.longitude : 0.0
        self.address = address
    }
}
