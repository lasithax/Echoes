import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let email: String
    let createdAt: Date
    
    init(name: String, email: String) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.createdAt = Date()
    }
    
    init(id: UUID, name: String, email: String, createdAt: Date) {
        self.id = id
        self.name = name
        self.email = email
        self.createdAt = createdAt
    }
}
