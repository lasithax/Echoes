//
//  ContentView.swift
//  Echoes
//
//  Created by Lasitha Udayanga on 2024-11-11.
//

import SwiftUI

struct ContentView: View {
    @State private var message: String = "Hello, World!"
    
    var body: some View {
        VStack {
            Text(message)
                .font(.largeTitle)
                .padding()
            
            Button(action: {
                // Change message when button is tapped
                message = "You tapped the button!"
            }) {
                Text("Tap Me")
                    .font(.title)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
