import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @Binding var showSignUp: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Echoes")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text("The Next Level Of Journaling")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.top, 60)
            .padding(.bottom, 80)
            
            // Login Form
            VStack(spacing: 20) {
                Text("Login")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Email Field
                TextField("Email", text: $email)
                    .padding()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .frame(height: 50)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.clear, lineWidth: 0)
                    )
                
                // Password Field
                SecureField("Password", text: $password)
                    .padding()
                    .frame(height: 50)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.clear, lineWidth: 0)
                    )
                
                // Error Message
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Login Button
                Button(action: {
                    loginUser()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        Text(isLoading ? "Logging in..." : "Log In")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(isLoading ? Color.green.opacity(0.7) : Color.green)
                    .cornerRadius(8)
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .padding(.top, 10)
                
                // Sign Up Navigation
                VStack(spacing: 10) {
                    Text("Still don't have an account?")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        showSignUp = true
                    }) {
                        Text("Create account")
                            .font(.caption)
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .background(Color.white)
        .ignoresSafeArea(.all, edges: .bottom)
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            hideKeyboard()
        }
    }
    
    // MARK: - Methods
    private func loginUser() {
        isLoading = true
        authManager.login(email: email, password: password) { success, error in
            isLoading = false
            if success {
                // Navigation will be handled automatically by ContentView
                email = ""
                password = ""
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(showSignUp: .constant(false))
            .environmentObject(AuthenticationManager())
    }
}
