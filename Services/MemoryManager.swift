import Foundation
import CoreData
import UIKit
import CoreLocation

class MemoryManager: ObservableObject {
    private let persistenceController = PersistenceController.shared
    
    @Published var memories: [EchoMemory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    private var currentUserId: String?
    
    init() {
        fetchMemories()
    }
    
    // User Context
    func setCurrentUser(_ user: User?) {
        currentUserId = user?.id.uuidString
        fetchMemories()
    }
    
    // Fetch Memories
    func fetchMemories() {
        isLoading = true
        errorMessage = nil
        
        let request: NSFetchRequest<EchoMemory> = EchoMemory.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \EchoMemory.date, ascending: false)]
        
        if let uid = currentUserId {
            request.predicate = NSPredicate(format: "userId == %@", uid)
        } else {
            request.predicate = NSPredicate(value: false)
        }
        
        do {
            memories = try persistenceController.container.viewContext.fetch(request)
            isLoading = false
        } catch {
            errorMessage = "Failed to fetch memories: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // Save Memory function
    func saveMemory(
        title: String,
        description: String,
        date: Date,
        location: CustomLocation,
        photo: UIImage? = nil,
        voiceNoteData: Data? = nil
    ) -> Bool {
        guard let uid = currentUserId else {
            errorMessage = "No authenticated user. Please sign in first."
            return false
        }
        
        let context = persistenceController.container.viewContext
        let memory = EchoMemory(context: context)
        
        memory.id = UUID()
        memory.title = title
        memory.memoryDescription = description
        memory.date = date
        memory.locationName = location.name
        // Ensuring coordinates are valid
        memory.latitude = location.latitude.isFinite ? location.latitude : 0.0
        memory.longitude = location.longitude.isFinite ? location.longitude : 0.0
        memory.createdAt = Date()
        memory.userId = uid
        
        // Handling photo
        if let photo = photo {
            memory.photoData = photo.jpegData(compressionQuality: 0.8)
            memory.hasPhoto = true
        } else {
            memory.hasPhoto = false
        }
        
        // Handling voice note
        if let voiceData = voiceNoteData {
            memory.voiceNoteData = voiceData
            memory.hasVoiceNote = true
        } else {
            memory.hasVoiceNote = false
        }
        
        do {
            try context.save()
            fetchMemories() // Refresh the list
            
            // Posting action for other views to refresh
            NotificationCenter.default.post(name: .memoriesDidChange, object: nil)
            
            return true
        } catch {
            errorMessage = "Failed to save memory: \(error.localizedDescription)"
            return false
        }
    }
    
    // Deleting Memory
    func deleteMemory(_ memory: EchoMemory) {
        let context = persistenceController.container.viewContext
        context.delete(memory)
        
        do {
            try context.save()
            fetchMemories() // Refresh the list
            
            // Posting action for other views to refresh
            NotificationCenter.default.post(name: .memoriesDidChange, object: nil)
        } catch {
            errorMessage = "Failed to delete memory: \(error.localizedDescription)"
        }
    }
    
    // Searching Memories
    func searchMemories(query: String) -> [EchoMemory] {
        if query.isEmpty {
            return memories
        }
        
        return memories.filter { memory in
            (memory.title?.localizedCaseInsensitiveContains(query) ?? false) ||
            (memory.memoryDescription?.localizedCaseInsensitiveContains(query) ?? false) ||
            (memory.locationName?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
    
    // Get Memory Photo
    func getPhoto(for memory: EchoMemory) -> UIImage? {
        guard let photoData = memory.photoData else { return nil }
        return UIImage(data: photoData)
    }
    
    // Fetch Memory Statistics
    func getMemoryCount() -> Int {
        return memories.count
    }
    
    func getLocationCount() -> Int {
        let uniqueLocations = Set(memories.compactMap { $0.locationName })
        return uniqueLocations.count
    }
    
    func getPhotoCount() -> Int {
        return memories.filter { $0.hasPhoto }.count
    }
    
    func getVoiceNoteCount() -> Int {
        return memories.filter { $0.hasVoiceNote }.count
    }
    
    // Finding Memory
    func findMemory(byIdString idString: String) -> EchoMemory? {
        memories.first { $0.id?.uuidString == idString }
    }
}

// EchoMemory Extensions
extension EchoMemory {
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
    
    var displayDate: Date {
        return date ?? createdAt ?? Date()
    }
    
    var displayTitle: String {
        return title ?? "Untitled Memory"
    }
    
    var displayDescription: String {
        return memoryDescription ?? ""
    }
    
    var displayLocationName: String {
        return locationName ?? "Unknown Location"
    }
}

// Notification Names
extension Notification.Name {
    static let memoriesDidChange = Notification.Name("memoriesDidChange")
}
