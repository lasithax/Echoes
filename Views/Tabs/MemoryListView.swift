//
//  MemoryListView.swift
//  Echoes
//
//  Created by Lasitha Udayanga on 2024-11-11.
//

import SwiftUI
import CoreData
import MapKit
import MessageUI

struct MemoryListView: View {
    @EnvironmentObject var memoryManager: MemoryManager
    @State private var searchText = ""
    @State private var selectedMemory: EchoMemory?
    
    var filteredMemories: [EchoMemory] {
        if searchText.isEmpty {
            return memoryManager.memories
        } else {
            return memoryManager.searchMemories(query: searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("My Memories")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text("\(memoryManager.memories.count) memories captured")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search memories...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Memories List
                if filteredMemories.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        
                        Image(systemName: "heart.text.square")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text(searchText.isEmpty ? "No memories yet" : "No matching memories")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        
                        Text(searchText.isEmpty ? "Create your first memory to get started" : "Try a different search term")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredMemories) { memory in
                                Button(action: { selectedMemory = memory }) {
                                    RealMemoryCard(memory: memory, memoryManager: memoryManager)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedMemory) { mem in
                EchoMemoryDetailView(memory: mem)
                    .environmentObject(memoryManager)
            }
        }
        .onAppear {
            memoryManager.fetchMemories()
        }
        .refreshable {
            memoryManager.fetchMemories()
        }
        .onReceive(NotificationCenter.default.publisher(for: .memoriesDidChange)) { _ in
            memoryManager.fetchMemories()
        }
    }
}

struct RealMemoryCard: View {
    let memory: EchoMemory
    let memoryManager: MemoryManager
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with date and location
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(memory.displayTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                    
                    Text(memory.displayDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text(memory.displayLocationName)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            // Description
            if !memory.displayDescription.isEmpty {
                Text(memory.displayDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            // Photo preview
            if memory.hasPhoto, let image = memoryManager.getPhoto(for: memory) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(8)
            }
            
            // Media indicators and actions
            HStack(spacing: 16) {
                if memory.hasPhoto {
                    HStack(spacing: 4) {
                        Image(systemName: "photo.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("Photo")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                if memory.hasVoiceNote {
                    HStack(spacing: 4) {
                        Image(systemName: "mic.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("Voice")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // Delete button
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .alert("Delete Memory", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                memoryManager.deleteMemory(memory)
            }
        } message: {
            Text("Are you sure you want to delete this memory? This action cannot be undone.")
        }
    }
}

struct EchoMemoryDetailView: View {
    @EnvironmentObject var memoryManager: MemoryManager
    let memory: EchoMemory
    @StateObject private var audioPlayer = AudioPlayer()
	@State private var mapRegion = MKCoordinateRegion(
		center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
		span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
	)
	@State private var showingShareSheet = false
	@State private var showingMessageComposer = false
	@State private var showMessageUnavailableAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Header with photo and overlay
                    ZStack(alignment: .bottomLeading) {
                        Group {
                            if memory.hasPhoto, let image = memoryManager.getPhoto(for: memory) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 240)
                                    .clipped()
                            } else {
                                LinearGradient(colors: [Color.green.opacity(0.4), Color.blue.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    .frame(height: 200)
                            }
                        }
                        LinearGradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                            .frame(height: 120)
                            .frame(maxWidth: .infinity, alignment: .bottom)
                            .allowsHitTesting(false)
                            .offset(y: 40)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(memory.displayTitle)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                            HStack(spacing: 8) {
                                Label(memory.displayLocationName, systemImage: "mappin.and.ellipse")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(6)
                                Text(memory.displayDate, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .padding(16)
                    }
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)

                    // Info cards
                    HStack(spacing: 12) {
                        InfoCard(icon: "calendar", title: "Date", value: DateFormatter.localizedString(from: memory.displayDate, dateStyle: .medium, timeStyle: .none))
                        InfoCard(icon: "location", title: "Location", value: memory.displayLocationName)
                    }

                    // Description
                    if !memory.displayDescription.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About this memory")
                                .font(.headline)
                            Text(memory.displayDescription)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .padding(16)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(12)
                    }

                    // Map preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.headline)
                        ZStack(alignment: .topTrailing) {
                            Map(coordinateRegion: $mapRegion, interactionModes: [], annotationItems: [MapPin(coordinate: memory.coordinate)]) { pin in
                                MapMarker(coordinate: pin.coordinate, tint: .red)
                            }
                            .frame(height: 200)
                            .cornerRadius(12)

                            HStack(spacing: 8) {
                                Button(action: { openInAppleMaps(driving: true) }) {
                                    Label("Drive", systemImage: "car.fill")
                                        .padding(8)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                Button(action: { openInAppleMaps(driving: false) }) {
                                    Label("Walk", systemImage: "figure.walk")
                                        .padding(8)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(10)
                        }
                    }

                    // Voice Note
                    if memory.hasVoiceNote, let data = memory.voiceNoteData {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Voice Note")
                                .font(.headline)
                            HStack(spacing: 12) {
                                Button(action: {
                                    if audioPlayer.isPlaying { audioPlayer.pause() } else { audioPlayer.play() }
                                }) {
                                    Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.blue)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    ProgressView(value: audioPlayer.duration > 0 ? (audioPlayer.currentTime / audioPlayer.duration) : 0)
                                    Text("\(formatTime(audioPlayer.currentTime)) / \(formatTime(audioPlayer.duration))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .onAppear { audioPlayer.load(data: data) }
                        }
                        .padding(16)
                        .background(Color.blue.opacity(0.06))
                        .cornerRadius(12)
                    }

					// Share
					VStack(alignment: .leading, spacing: 10) {
						Text("Share")
							.font(.headline)
						HStack(spacing: 12) {
							Button(action: { showingShareSheet = true }) {
								Label("Share this memory", systemImage: "square.and.arrow.up")
									.font(.subheadline)
									.padding(.vertical, 10)
									.padding(.horizontal, 14)
									.background(Color.accentColor)
									.foregroundColor(.white)
									.cornerRadius(10)
							}
							Button(action: {
								if MFMessageComposeViewController.canSendText() {
									showingMessageComposer = true
								} else {
									showMessageUnavailableAlert = true
								}
							}) {
								Label("Message", systemImage: "message.fill")
									.font(.subheadline)
									.padding(.vertical, 10)
									.padding(.horizontal, 14)
									.background(Color.green)
									.foregroundColor(.white)
									.cornerRadius(10)
							}
						}
					}
                }
                .padding()
            }
            .navigationTitle("Memory Details")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismissView() }
                }
            }
            .onAppear {
                let coord = memory.coordinate
                if coord.latitude.isFinite, coord.longitude.isFinite, CLLocationCoordinate2DIsValid(coord) {
                    mapRegion = MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                }
            }
			.sheet(isPresented: $showingShareSheet) {
				ActivityShareView(activityItems: buildShareItems())
			}
			.sheet(isPresented: $showingMessageComposer) {
				MessageComposeView(initialText: composeShareText(), attachments: buildMessageAttachments()) { _ in }
			}
			.alert("Messages Unavailable", isPresented: $showMessageUnavailableAlert) {
				Button("OK", role: .cancel) {}
			} message: {
				Text("This device is not configured to send iMessages.")
			}
        }
    }
    
    private func dismissView() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func openInAppleMaps(driving: Bool) {
        let coord = memory.coordinate
        guard coord.latitude.isFinite,
              coord.longitude.isFinite,
              CLLocationCoordinate2DIsValid(coord) else { return }

        let placemark = MKPlacemark(coordinate: coord)
        let item = MKMapItem(placemark: placemark)
        item.name = memory.displayLocationName
        let mode = driving ? MKLaunchOptionsDirectionsModeDriving : MKLaunchOptionsDirectionsModeWalking
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: mode])
    }
}

// MARK: - Share Helpers
extension EchoMemoryDetailView {
	private func composeShareText() -> String {
		var text = "\(memory.displayTitle) — \(DateFormatter.localizedString(from: memory.displayDate, dateStyle: .medium, timeStyle: .short))\nLocation: \(memory.displayLocationName)"
		let desc = memory.displayDescription.trimmingCharacters(in: .whitespacesAndNewlines)
		if !desc.isEmpty { text += "\n\n\(desc)" }
		return text
	}

	private func buildShareItems() -> [Any] {
		var items: [Any] = [composeShareText()]
		if let data = memory.photoData, let image = UIImage(data: data) {
			items.append(image)
		}
		if let url = buildTempAudioURL() {
			items.append(url)
		}
		return items
	}

	private func buildTempAudioURL() -> URL? {
		guard let data = memory.voiceNoteData else { return nil }
		let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("memory_\(memory.id?.uuidString ?? UUID().uuidString).m4a")
		try? data.write(to: tmp, options: .atomic)
		return tmp
	}

	private func buildMessageAttachments() -> [MessageAttachment] {
		var attachments: [MessageAttachment] = []
		if let data = memory.photoData {
			attachments.append(MessageAttachment(data: data, typeIdentifier: "public.jpeg", filename: "photo.jpg"))
		}
		if let data = memory.voiceNoteData {
			attachments.append(MessageAttachment(data: data, typeIdentifier: "public.mpeg-4-audio", filename: "voice.m4a"))
		}
		return attachments
	}
}

// Activity
struct ActivityShareView: UIViewControllerRepresentable {
	let activityItems: [Any]

	func makeUIViewController(context: Context) -> UIActivityViewController {
		UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
	}

	func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Message Composer
struct MessageAttachment {
	let data: Data
	let typeIdentifier: String
	let filename: String
}

struct MessageComposeView: UIViewControllerRepresentable {
	let initialText: String
	let attachments: [MessageAttachment]
	var onFinish: (MessageComposeResult) -> Void = { _ in }

	func makeCoordinator() -> Coordinator { Coordinator(self) }

	func makeUIViewController(context: Context) -> MFMessageComposeViewController {
		let vc = MFMessageComposeViewController()
		vc.messageComposeDelegate = context.coordinator
		vc.body = initialText
		for att in attachments {
			vc.addAttachmentData(att.data, typeIdentifier: att.typeIdentifier, filename: att.filename)
		}
		return vc
	}

	func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

	class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
		let parent: MessageComposeView
		init(_ parent: MessageComposeView) { self.parent = parent }
		func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
			controller.dismiss(animated: true) {
				self.parent.onFinish(result)
			}
		}
	}
}

private struct InfoCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }
}

private struct MapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// Mock Memory Model for demonstration
struct MockMemory: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let date: Date
    let location: String
    let hasPhoto: Bool
    let hasVoiceNote: Bool
    
    static let sampleMemories: [MockMemory] = [
        MockMemory(
            title: "Coffee with Sarah",
            description: "Had an amazing conversation about life and future plans. The weather was perfect and we sat outside for hours.",
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            location: "Central Park",
            hasPhoto: true,
            hasVoiceNote: false
        ),
        MockMemory(
            title: "Morning Run",
            description: "Best run in weeks! Felt energized and accomplished. The sunrise was breathtaking over the lake.",
            date: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
            location: "Lakeside Trail",
            hasPhoto: false,
            hasVoiceNote: true
        ),
        MockMemory(
            title: "Family Dinner",
            description: "Wonderful evening with the family. Mom made her famous lasagna and we played board games afterward.",
            date: Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date(),
            location: "Home",
            hasPhoto: true,
            hasVoiceNote: true
        ),
        MockMemory(
            title: "Concert Night",
            description: "Incredible live music performance. The energy was electric and the crowd was amazing.",
            date: Calendar.current.date(byAdding: .weekOfYear, value: -2, to: Date()) ?? Date(),
            location: "Madison Square Garden",
            hasPhoto: true,
            hasVoiceNote: false
        )
    ]
}

struct MemoryListView_Previews: PreviewProvider {
    static var previews: some View {
        MemoryListView()
    }
}
