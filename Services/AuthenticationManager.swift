import Foundation
import SwiftUI

/// Credentials record saved in UserDefaults.
struct UserCredentials: Codable {
    let email: String
    let password: String
    let user: User
}

/// Outputs the current auth state so SwiftUI can act accordingly.
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    
    private let credentialsKey = "echoes_user_credentials"
    private let currentUserKey = "echoes_current_user"
    
    init() {
        checkAuthenticationStatus()
    }
    
    /// Loading the last logged-in user from UserDefaults
    func checkAuthenticationStatus() {
        if let userData = UserDefaults.standard.data(forKey: currentUserKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = user
            isAuthenticated = true
        }
    }
    
    /// Createing a new local user if inputs are valid and email is not taken.
    /// The new user is considered “logged in” instantly.
    func signUp(name: String, email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        DispatchQueue.main.async {
            self.errorMessage = nil
            
            // Basic input validations
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            guard !trimmedName.isEmpty else {
                self.errorMessage = "Name cannot be empty"
                completion(false, "Name cannot be empty")
                return
            }
            
            guard self.isValidEmail(trimmedEmail) else {
                self.errorMessage = "Please enter a valid email address"
                completion(false, "Please enter a valid email address")
                return
            }
            
            guard password.count >= 6 else {
                self.errorMessage = "Password must be at least 6 characters long"
                completion(false, "Password must be at least 6 characters long")
                return
            }
            
            // Avoid duplicate accounts with the same email
            if self.userExists(email: trimmedEmail) {
                self.errorMessage = "An account with this email already exists"
                completion(false, "An account with this email already exists")
                return
            }
            
            // Create and store the user locally
            let newUser = User(name: trimmedName, email: trimmedEmail)
            let credentials = UserCredentials(email: trimmedEmail, password: password, user: newUser)
            
            if self.saveUserCredentials(credentials) {
                self.currentUser = newUser
                self.isAuthenticated = true
                self.saveCurrentUser(newUser)
                completion(true, nil)
            } else {
                self.errorMessage = "Failed to create account. Please try again."
                completion(false, "Failed to create account. Please try again.")
            }
        }
    }
    
    /// Attemptting to find a matching local user for email + password.
    func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        DispatchQueue.main.async {
            self.errorMessage = nil
            
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            guard !trimmedEmail.isEmpty else {
                self.errorMessage = "Email cannot be empty"
                completion(false, "Email cannot be empty")
                return
            }
            
            guard !password.isEmpty else {
                self.errorMessage = "Password cannot be empty"
                completion(false, "Password cannot be empty")
                return
            }
            
            // Looking up the stored credentials for this email
            let allCredentials = self.getAllUserCredentials()
            
            if let userCredentials = allCredentials.first(where: { $0.email == trimmedEmail }) {
                if userCredentials.password == password {
                    // Successful login
                    self.currentUser = userCredentials.user
                    self.isAuthenticated = true
                    self.saveCurrentUser(userCredentials.user)
                    completion(true, nil)
                } else {
                    self.errorMessage = "Invalid email or password"
                    completion(false, "Invalid email or password")
                }
            } else {
                self.errorMessage = "Invalid email or password"
                completion(false, "Invalid email or password")
            }
        }
    }
    
    /// Logging the current user out and clears the in-memory state.
    func logout() {
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: currentUserKey)
    }
    
    // Helper Methods
    /// Email validation
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Returns true if an account already exists for the given email
    private func userExists(email: String) -> Bool {
        let allCredentials = getAllUserCredentials()
        return allCredentials.contains { $0.email == email }
    }
    
    /// Loading all locally stored credentials from UserDefaults
    private func getAllUserCredentials() -> [UserCredentials] {
        guard let data = UserDefaults.standard.data(forKey: credentialsKey),
              let credentials = try? JSONDecoder().decode([UserCredentials].self, from: data) else {
            return []
        }
        return credentials
    }
    
    /// Savesinga new credentials record into UserDefaults
    private func saveUserCredentials(_ newCredentials: UserCredentials) -> Bool {
        var allCredentials = getAllUserCredentials()
        allCredentials.append(newCredentials)
        
        guard let data = try? JSONEncoder().encode(allCredentials) else {
            return false
        }
        
        UserDefaults.standard.set(data, forKey: credentialsKey)
        return true
    }
    
    /// Saving the current user so the app can auto login later
    private func saveCurrentUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: currentUserKey)
        }
    }
}
