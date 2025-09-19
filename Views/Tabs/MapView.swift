//
//  MapView.swift
//  Echoes
//
//  Created by Lasitha Udayanga on 2024-11-11.
//

import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var memoryManager: MemoryManager
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var searchText: String = ""
    @State private var selectedMemory: EchoMemory?
    @State private var showingMemoryDetail = false
    
    private var mapItems: [MapItem] {
        memoryManager.memories.compactMap { mem in
            let coord = mem.coordinate
            guard coord.latitude.isFinite, coord.longitude.isFinite, CLLocationCoordinate2DIsValid(coord) else { return nil }
            return MapItem(id: mem.id?.uuidString ?? mem.objectID.uriRepresentation().absoluteString,
                           memory: mem,
                           coordinate: coord,
                           title: mem.displayTitle,
                           locationName: mem.displayLocationName)
        }
    }
    
    private var filteredItems: [MapItem] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return mapItems }
        let q = searchText.lowercased()
        return mapItems.filter { item in
            item.title.lowercased().contains(q) ||
            (item.memory.memoryDescription ?? "").lowercased().contains(q) ||
            item.locationName.lowercased().contains(q)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Map
                Map(coordinateRegion: $region, annotationItems: filteredItems) { item in
                    MapAnnotation(coordinate: item.coordinate) {
                        Button(action: {
                            selectedMemory = item.memory
                            showingMemoryDetail = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 30, height: 30)
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .ignoresSafeArea(.all, edges: .bottom)
                
                VStack(spacing: 12) {
                    // Header and Search
                    VStack(spacing: 8) {
                        Text("Memory Map")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Text("\(mapItems.count) memories on the map")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").foregroundColor(.gray)
                        TextField("Search by title, description, place...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
                    .padding(.horizontal, 20)
                    
                    if !searchText.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(filteredItems.prefix(5)) { item in
                                Button {
                                    centerOn(item.coordinate, zoom: 0.01)
                                    selectedMemory = item.memory
                                    showingMemoryDetail = true
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "mappin.circle.fill").foregroundColor(.green)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.title).font(.subheadline).foregroundColor(.black)
                                            Text(item.locationName).font(.caption).foregroundColor(.gray)
                                        }
                                        Spacer()
                                    }
                                    .padding(10)
                                }
                                .buttonStyle(PlainButtonStyle())
                                if item.id != filteredItems.prefix(5).last?.id {
                                    Divider()
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    // Map Controls
                    HStack(spacing: 12) {
                        Button(action: { centerOnUserLocation() }) {
                            Image(systemName: "location.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.blue)
                                .cornerRadius(25)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        Button(action: { zoomToFit(items: filteredItems) }) {
                            Image(systemName: "viewfinder")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.green)
                                .cornerRadius(25)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingMemoryDetail) {
            if let mem = selectedMemory {
                EchoMemoryDetailView(memory: mem)
                    .environmentObject(memoryManager)
            }
        }
        .onAppear {
            memoryManager.fetchMemories()
            zoomToFit(items: filteredItems)
        }
        .onChange(of: memoryManager.memories) { _ in
            zoomToFit(items: filteredItems)
        }
    }
    
    private func centerOnUserLocation() {
        // Center to a placeholder until user selects a location
        withAnimation(.easeInOut(duration: 0.8)) {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    private func centerOn(_ coordinate: CLLocationCoordinate2D, zoom: CLLocationDegrees) {
        guard coordinate.latitude.isFinite, coordinate.longitude.isFinite else { return }
        withAnimation(.easeInOut(duration: 0.8)) {
            region = MKCoordinateRegion(center: coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: zoom, longitudeDelta: zoom))
        }
    }
    
    private func zoomToFit(items: [MapItem]) {
        guard !items.isEmpty else { return }
        let coords = items.map { $0.coordinate }
        let lats = coords.map { $0.latitude }.filter { $0.isFinite }
        let lons = coords.map { $0.longitude }.filter { $0.isFinite }
        guard let minLat = lats.min(), let maxLat = lats.max(), let minLon = lons.min(), let maxLon = lons.max() else { return }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat)/2, longitude: (minLon + maxLon)/2)
        let span = MKCoordinateSpan(latitudeDelta: max(maxLat-minLat, 0.01)*1.2, longitudeDelta: max(maxLon-minLon, 0.01)*1.2)
        withAnimation(.easeInOut(duration: 0.8)) {
            region = MKCoordinateRegion(center: center, span: span)
        }
    }
}

struct MapItem: Identifiable {
    let id: String
    let memory: EchoMemory
    let coordinate: CLLocationCoordinate2D
    let title: String
    let locationName: String
}
