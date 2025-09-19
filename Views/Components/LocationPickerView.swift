import SwiftUI
import MapKit

struct LocationPickerView: View {
    @Binding var selectedLocation: CustomLocation?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    @State private var customLocationName = ""
    @State private var showingCustomLocationAlert = false
    @State private var tempLocation: CLLocationCoordinate2D?
    @State private var isLoadingLocationName = false
    
    // Search states
    @State private var searchText: String = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching: Bool = false
    
    // Filter out locations with invalid coordinates
    private var validSelectedLocations: [CustomLocation] {
        guard let location = selectedLocation else { return [] }
        
        if location.coordinate.latitude.isFinite &&
           location.coordinate.longitude.isFinite &&
           CLLocationCoordinate2DIsValid(location.coordinate) {
            return [location]
        }
        return []
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Instructions
                VStack(spacing: 8) {
                    Text("Choose Location")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text("Tap on the map, search, or use your current location")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                
                // Search Bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(.gray)
                    TextField("Search places (e.g. Powell St, San Francisco)", text: $searchText, onCommit: {
                        performSearch()
                    })
                    .textFieldStyle(PlainTextFieldStyle())
                    .submitLabel(.search)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults.removeAll()
                        }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                        }
                    }
                    
                    Button(action: { performSearch() }) {
                        Text("Search").font(.caption).foregroundColor(.blue)
                    }
                }
                .padding(10)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                // Results list
                if isSearching {
                    HStack { ProgressView(); Spacer() }.padding(.horizontal, 16)
                }
                if !searchResults.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(searchResults.prefix(6).enumerated()), id: \.offset) { _, item in
                            Button(action: { selectSearchResult(item) }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "mappin.circle.fill").foregroundColor(.green)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name ?? "Unnamed")
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                        Text(item.placemark.title ?? "")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                }
                                .padding(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                            if item != searchResults.prefix(6).last {
                                Divider()
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
                
                // Map
                ZStack {
                    Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: true, annotationItems: validSelectedLocations) { location in
                        MapAnnotation(coordinate: location.coordinate) {
                            VStack {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.red)
                                
                                Text(location.name)
                                    .font(.caption)
                                    .padding(4)
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .onTapGesture(coordinateSpace: .local) { location in
                        handleMapTap(at: location)
                    }
                    
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.red)
                        .allowsHitTesting(false)
                }
                
                // Controls
                VStack(spacing: 16) {
                    // Current Location Button
                    Button(action: {
                        useCurrentLocation()
                    }) {
                        HStack {
                            if locationManager.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "location.fill")
                                    .font(.title3)
                            }
                            
                            Text(locationManager.isLoading ? "Getting Location..." : "Use Current Location")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(locationManager.isLoading)
                    
                    // Use Center Location Button
                    Button(action: {
                        useCenterLocation()
                    }) {
                        HStack {
                            if isLoadingLocationName {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.title3)
                            }
                            
                            Text(isLoadingLocationName ? "Loading..." : "Use Center Location")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    .disabled(isLoadingLocationName)
                    
                    // Error Message
                    if let errorMessage = locationManager.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(selectedLocation == nil)
                }
            }
        }
        .onAppear {
            locationManager.requestLocationPermission()
        }
        .onChange(of: locationManager.location) { newLocation in
            if let location = newLocation {
                updateRegion(to: location.coordinate)
            }
        }
        .alert("Custom Location Name", isPresented: $showingCustomLocationAlert) {
            TextField("Enter location name", text: $customLocationName)
            Button("Cancel", role: .cancel) {
                tempLocation = nil
                customLocationName = ""
            }
            Button("Save") {
                if let tempLoc = tempLocation {
                    let location = CustomLocation(
                        name: customLocationName.isEmpty ? "Custom Location" : customLocationName,
                        latitude: tempLoc.latitude,
                        longitude: tempLoc.longitude
                    )
                    selectedLocation = location
                    tempLocation = nil
                    customLocationName = ""
                }
            }
        } message: {
            Text("Enter a name for this location")
        }
    }
    
    private func handleMapTap(at point: CGPoint) {
        // Convert tap point to coordinate
        let coordinate = region.center
        tempLocation = coordinate
        showingCustomLocationAlert = true
    }
    
    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults.removeAll()
            return
        }
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region
        MKLocalSearch(request: request).start { response, error in
            DispatchQueue.main.async {
                self.isSearching = false
                if let items = response?.mapItems {
                    self.searchResults = items
                } else {
                    self.searchResults = []
                }
            }
        }
    }
    
    private func selectSearchResult(_ item: MKMapItem) {
        let coord = item.placemark.coordinate
        updateRegion(to: coord)
        let name = item.name ?? item.placemark.title ?? "Selected Location"
        let address = item.placemark.title
        let loc = CustomLocation(name: name, latitude: coord.latitude, longitude: coord.longitude, address: address)
        selectedLocation = loc
        searchResults.removeAll()
        searchText = name
    }
    
    private func useCurrentLocation() {
        locationManager.getCurrentLocation()
        
        guard let location = locationManager.location else { return }
        
        isLoadingLocationName = true
        locationManager.getLocationName(for: location) { locationName in
            let customLocation = CustomLocation(
                name: locationName,
                location: location
            )
            selectedLocation = customLocation
            updateRegion(to: location.coordinate)
            isLoadingLocationName = false
        }
    }
    
    private func useCenterLocation() {
        let centerLocation = CLLocation(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        )
        
        isLoadingLocationName = true
        locationManager.getLocationName(for: centerLocation) { locationName in
            let customLocation = CustomLocation(
                name: locationName,
                location: centerLocation
            )
            selectedLocation = customLocation
            isLoadingLocationName = false
        }
    }
    
    private func updateRegion(to coordinate: CLLocationCoordinate2D) {
        // Validate coordinates before updating region
        guard coordinate.latitude.isFinite,
              coordinate.longitude.isFinite,
              CLLocationCoordinate2DIsValid(coordinate) else {
            print("Invalid coordinate provided to updateRegion: \(coordinate)")
            return
        }
        
        withAnimation(.easeInOut(duration: 1.0)) {
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
}

struct LocationPickerView_Previews: PreviewProvider {
    static var previews: some View {
        LocationPickerView(selectedLocation: .constant(nil))
    }
}
