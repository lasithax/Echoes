import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var memoryManager = MemoryManager()
    @StateObject private var notificationsManager = NotificationsManager()
    @StateObject private var geofenceManager: GeofenceManager
    @State private var selectedTab = 0
    
    // State to present a memory detail when coming from a notification
    @State private var deepLinkMemory: EchoMemory?
    @State private var showDeepLinkDetail = false
    
    init() {
        let notifications = NotificationsManager()
        _notificationsManager = StateObject(wrappedValue: notifications)
        _geofenceManager = StateObject(wrappedValue: GeofenceManager(notifications: notifications))
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Create Memory Tab
            CreateMemoryView()
                .environmentObject(memoryManager)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "plus.circle.fill" : "plus.circle")
                    Text("Create")
                }
                .tag(0)
            
            // Memory List Tab
            MemoryListView()
                .environmentObject(memoryManager)
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "heart.text.square.fill" : "heart.text.square")
                    Text("Memories")
                }
                .tag(1)
            
            // Map Tab
            MapView()
                .environmentObject(memoryManager)
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "map.fill" : "map")
                    Text("Map")
                }
                .tag(2)
            
            // Profile Tab
            ProfileView()
                .environmentObject(authManager)
                .environmentObject(memoryManager)
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "person.circle.fill" : "person.circle")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(.green)
        .onAppear {
            // Configure notifications and request auth once
            notificationsManager.configure()
            notificationsManager.requestAuthorization { granted in
                if granted {
                    geofenceManager.requestAlwaysAuthorization()
                    // Initial sync
                    geofenceManager.syncRegions(memories: memoryManager.memories)
                }
            }
            // Feed the current user into memory manager when app shows
            memoryManager.setCurrentUser(authManager.currentUser)
        }
        .onReceive(NotificationCenter.default.publisher(for: .memoriesDidChange)) { _ in
            geofenceManager.syncRegions(memories: memoryManager.memories)
        }
        .onChange(of: memoryManager.memories) { _ in
            geofenceManager.syncRegions(memories: memoryManager.memories)
        }
        .onChange(of: authManager.currentUser) { newUser in
            // Refetch memories when login/logout or user switch occurs
            memoryManager.setCurrentUser(newUser)
        }
        .onChange(of: selectedTab) { _ in
            // Keep regions up to date when switching tabs
            geofenceManager.syncRegions(memories: memoryManager.memories)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // If a Siri/Shortcut set the flag, open the Create tab on resume
            if UserDefaults.standard.bool(forKey: "shortcut_open_create_memory") {
                UserDefaults.standard.set(false, forKey: "shortcut_open_create_memory")
                selectedTab = 0
            }
        }
        .onChange(of: notificationsManager.tappedMemoryId) { id in
            guard let id, let mem = memoryManager.findMemory(byIdString: id) else { return }
            deepLinkMemory = mem
            selectedTab = 1 // Memories tab
            showDeepLinkDetail = true
        }
        .sheet(isPresented: $showDeepLinkDetail) {
            if let mem = deepLinkMemory {
                EchoMemoryDetailView(memory: mem)
                    .environmentObject(memoryManager)
            }
        }
    }
}

struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        let authManager = AuthenticationManager()
        // Set up a mock authenticated user for preview
        authManager.currentUser = User(name: "John Doe", email: "john@example.com")
        authManager.isAuthenticated = true
        
        return MainAppView()
            .environmentObject(authManager)
    }
}
