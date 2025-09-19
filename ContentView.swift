import UserNotifications
import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
    @State private var showSignUp: Bool = false
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainAppView()
                    .environmentObject(authManager)
            } else {
                NavigationView {
                    if showSignUp {
                        SignUpView(showSignUp: $showSignUp)
                            .environmentObject(authManager)
                    } else {
                        LoginView(showSignUp: $showSignUp)
                            .environmentObject(authManager)
                    }
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
        }
        .onAppear {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                guard granted else { return }
                let content = UNMutableNotificationContent()
                content.title = "Welcome to Echoes"
                content.body = "Notifications are enabled."
                content.sound = .default
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
                let request = UNNotificationRequest(identifier: "app_launch_welcome", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
