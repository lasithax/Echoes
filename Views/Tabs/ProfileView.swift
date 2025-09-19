//
//  ProfileView.swift
//  Echoes
//
//  Created by Lasitha Udayanga on 2024-11-11.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var memoryManager: MemoryManager
    @State private var showingSettings = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Profile")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        Text("Manage your account and preferences")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    // User Info Card
                    if let user = authManager.currentUser {
                        VStack(spacing: 16) {
                            // Profile Picture Placeholder
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                
                                Text(String(user.name.prefix(1)).uppercased())
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            
                            // User Details
                            VStack(spacing: 8) {
                                Text(user.name)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                
                                Text(user.email)
                                    .font(.body)
                                    .foregroundColor(.gray)
                                
                                Text("Member since \(user.createdAt, style: .date)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    
                    // Statistics Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Echoes")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                        
                        HStack(spacing: 20) {
                            StatisticView(
                                icon: "heart.text.square.fill",
                                title: "Memories",
                                value: String(memoryManager.getMemoryCount()),
                                color: .green
                            )
                            
                            StatisticView(
                                icon: "location.fill",
                                title: "Locations",
                                value: String(memoryManager.getLocationCount()),
                                color: .blue
                            )
                            
                            StatisticView(
                                icon: "photo.fill",
                                title: "Photos",
                                value: String(memoryManager.getPhotoCount()),
                                color: .orange
                            )
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    
                    // Settings Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Settings")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            SettingsRow(
                                icon: "bell.fill",
                                title: "Notifications",
                                subtitle: "Manage location-based reminders",
                                color: .orange
                            ) {
                                showingSettings = true
                            }
                            
                            Divider()
                                .padding(.leading, 50)
                            
                            SettingsRow(
                                icon: "lock.fill",
                                title: "Privacy",
                                subtitle: "Control your data and privacy",
                                color: .blue
                            ) {
                                showingSettings = true
                            }
                            
                            Divider()
                                .padding(.leading, 50)
                            
                            SettingsRow(
                                icon: "icloud.fill",
                                title: "Backup & Sync",
                                subtitle: "Keep your memories safe",
                                color: .green
                            ) {
                                showingSettings = true
                            }
                            
                            Divider()
                                .padding(.leading, 50)
                            
                            SettingsRow(
                                icon: "info.circle.fill",
                                title: "About",
                                subtitle: "App version and information",
                                color: .gray
                            ) {
                                showingAbout = true
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    
                    // Logout Button
                    Button(action: {
                        authManager.logout()
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.headline)
                            
                            Text("Sign Out")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet()
        }
        .sheet(isPresented: $showingAbout) {
            AboutSheet()
        }
        .onAppear {
            memoryManager.fetchMemories()
        }
    }
}

struct StatisticView: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Settings coming soon!")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // App Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.green)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                .padding(.top, 40)
                
                // App Info
                VStack(spacing: 8) {
                    Text("Echoes")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text("The Next Level Of Journaling")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }
                
                // Description
                Text("Capture your memories and tie them to the places that matter. Echoes helps you create location-based memory capsules that remind you of special moments when you return to those places.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // Credits
                VStack(spacing: 4) {
                    Text("Made with ❤️")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("© 2024 Echoes App")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthenticationManager())
            .environmentObject(MemoryManager())
    }
}
