import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var name: String = ""
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
            
            // Sign Up Form
            VStack(spacing: 20) {
                Text("Sign Up")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Name Field
                TextField("Name", text: $name)
                    .padding()
                    .textInputAutocapitalization(.words)
                    .frame(height: 50)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.clear, lineWidth: 0)
                    )
                
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
                
                // Sign Up Button
                Button(action: {
                    signUpUser()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        Text(isLoading ? "Creating account..." : "Sign up")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(isLoading ? Color.green.opacity(0.7) : Color.green)
                    .cornerRadius(8)
                }
                .disabled(isLoading || name.isEmpty || email.isEmpty || password.isEmpty)
                .padding(.top, 10)
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .background(Color.white)
        .ignoresSafeArea(.all, edges: .bottom)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    showSignUp = false
                }
                .foregroundColor(.green)
            }
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            hideKeyboard()
        }
    }
    
    // Methods
    private func signUpUser() {
        isLoading = true
        authManager.signUp(name: name, email: email, password: password) { success, error in
            isLoading = false
            if success {
                // Navigation will be handled automatically by ContentView
                name = ""
                email = ""
                password = ""
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView(showSignUp: .constant(true))
            .environmentObject(AuthenticationManager())
    }
}
