import SwiftUI
import MapKit

struct CreateMemoryView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var audioRecorder = AudioRecorder()
    @EnvironmentObject var memoryManager: MemoryManager
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedDate = Date()
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingLocationPicker = false
    @State private var selectedLocation: CustomLocation?
    @State private var isSaving = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Create Memory")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        Text("Capture this moment and location")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    // Memory Form
                    VStack(spacing: 16) {
                        // Title Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            TextField("What happened here?", text: $title)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        }
                        
                        // Description Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            TextEditor(text: $description)
                                .padding()
                                .frame(minHeight: 100)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        }
                        
                        // Date Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        }
                        
                        // Photo Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Photo")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            if let selectedImage = selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 200)
                                    .cornerRadius(12)
                                    .onTapGesture {
                                        showingImagePicker = true
                                    }
                            } else {
                                Button(action: {
                                    showingImagePicker = true
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "camera.fill")
                                            .font(.title2)
                                            .foregroundColor(.gray)
                                        
                                        Text("Add Photo")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    .frame(height: 120)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        
                        // Voice Note Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Voice Note")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            if audioRecorder.hasRecording {
                                // Recording exists - show playback controls
                                VStack(spacing: 12) {
                                    HStack {
                                        Button(action: {
                                            if audioRecorder.isPlaying {
                                                audioRecorder.stopPlayback()
                                            } else {
                                                audioRecorder.startPlayback()
                                            }
                                        }) {
                                            Image(systemName: audioRecorder.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                                .font(.title)
                                                .foregroundColor(.blue)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Recording (\(audioRecorder.formattedTime(audioRecorder.recordingTime)))")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.black)
                                            
                                            Text(audioRecorder.isPlaying ? "Playing..." : "Tap to play")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Button("Delete") {
                                            audioRecorder.clearRecording()
                                        }
                                        .font(.caption)
                                        .foregroundColor(.red)
                                    }
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            } else {
                                // No recording - show record button
                                Button(action: {
                                    if audioRecorder.isRecording {
                                        audioRecorder.stopRecording()
                                    } else {
                                        audioRecorder.startRecording()
                                    }
                                }) {
                                    HStack {
                                        if audioRecorder.isRecording {
                                            Image(systemName: "stop.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.red)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Recording...")
                                                    .font(.subheadline)
                                                    .foregroundColor(.red)
                                                
                                                Text(audioRecorder.formattedTime(audioRecorder.recordingTime))
                                                    .font(.caption)
                                                    .foregroundColor(.red)
                                            }
                                        } else {
                                            Image(systemName: "mic.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.blue)
                                            
                                            Text("Record Voice Note")
                                                .font(.subheadline)
                                                .foregroundColor(.blue)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding()
                                    .background(audioRecorder.isRecording ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                            
                            // Audio Error Message
                            if let errorMessage = audioRecorder.errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Location Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            if let location = selectedLocation {
                                // Selected Location Display
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.green)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(location.name)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.black)
                                            
                                            if let address = location.address {
                                                Text(address)
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Button("Change") {
                                            showingLocationPicker = true
                                        }
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                            } else {
                                // Location Selection Buttons
                                VStack(spacing: 8) {
                                    Button(action: {
                                        useCurrentLocation()
                                    }) {
                                        HStack {
                                            if locationManager.isLoading {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                            } else {
                                                Image(systemName: "location.fill")
                                                    .font(.title2)
                                            }
                                            
                                            Text(locationManager.isLoading ? "Getting Location..." : "Use Current Location")
                                                .font(.subheadline)
                                            
                                            Spacer()
                                        }
                                        .foregroundColor(.blue)
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                    .disabled(locationManager.isLoading)
                                    
                                    Button(action: {
                                        showingLocationPicker = true
                                    }) {
                                        HStack {
                                            Image(systemName: "map")
                                                .font(.title2)
                                                .foregroundColor(.green)
                                            
                                            Text("Choose on Map")
                                                .font(.subheadline)
                                                .foregroundColor(.green)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .padding()
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            
                            // Location Error
                            if let errorMessage = locationManager.errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Save Button
                        Button(action: {
                            saveMemory()
                        }) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                }
                                
                                Text(isSaving ? "Saving..." : "Save Memory")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(canSave ? Color.green : Color.gray)
                            .cornerRadius(12)
                        }
                        .disabled(!canSave || isSaving)
                        .padding(.top, 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showingLocationPicker) {
            LocationPickerView(selectedLocation: $selectedLocation)
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("View Memories") {
                clearForm()
                // Switch to memories tab
                if let tabView = UIApplication.shared.windows.first?.rootViewController?.view.subviews.first(where: { $0 is UITabBar }) as? UITabBar {
                    tabView.selectedItem = tabView.items?[1]
                }
            }
            Button("Create Another") {
                clearForm()
            }
        } message: {
            Text("Memory saved successfully!")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            locationManager.requestLocationPermission()
        }
    }
    
    // MARK: - Computed Properties
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedLocation != nil
    }
    
    // MARK: - Methods
    private func useCurrentLocation() {
        print("DEBUG: useCurrentLocation called")
        
        // Check current authorization status
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("DEBUG: Location already authorized, getting location")
            getCurrentLocationAndProcess()
        case .notDetermined:
            print("DEBUG: Location permission not determined, requesting")
            locationManager.requestLocationPermission()
            // Wait for permission response, then try to get location
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if self.locationManager.authorizationStatus == .authorizedWhenInUse || 
                   self.locationManager.authorizationStatus == .authorizedAlways {
                    self.getCurrentLocationAndProcess()
                }
            }
        case .denied, .restricted:
            print("DEBUG: Location permission denied")
            // Permission already denied, show error
            break
        @unknown default:
            print("DEBUG: Unknown location permission status")
            break
        }
    }
    
    private func getCurrentLocationAndProcess() {
        print("DEBUG: getCurrentLocationAndProcess called")
        locationManager.getCurrentLocation()
        
        // Monitor for location updates
        let startTime = Date()
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if let location = self.locationManager.location {
                print("DEBUG: Got location, processing...")
                timer.invalidate()
                
                self.locationManager.getLocationName(for: location) { locationName in
                    DispatchQueue.main.async {
                        let customLocation = CustomLocation(
                            name: locationName,
                            location: location,
                            address: locationName
                        )
                        self.selectedLocation = customLocation
                        print("DEBUG: Location set successfully")
                    }
                }
            } else if Date().timeIntervalSince(startTime) > 10.0 {
                print("DEBUG: Location timeout reached")
                timer.invalidate()
            }
        }
    }
    
    private func saveMemory() {
        guard canSave else { return }
        guard let location = selectedLocation else { return }
        
        isSaving = true
        
        let success = memoryManager.saveMemory(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            date: selectedDate,
            location: location,
            photo: selectedImage,
            voiceNoteData: audioRecorder.getRecordingData()
        )
        
        isSaving = false
        
        if success {
            showingSuccessAlert = true
        } else {
            alertMessage = memoryManager.errorMessage ?? "Failed to save memory"
            showingErrorAlert = true
        }
    }
    
    private func clearForm() {
        title = ""
        description = ""
        selectedDate = Date()
        selectedImage = nil
        selectedLocation = nil
        audioRecorder.clearRecording()
    }
}

// Simple Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct CreateMemoryView_Previews: PreviewProvider {
    static var previews: some View {
        CreateMemoryView()
    }
}
