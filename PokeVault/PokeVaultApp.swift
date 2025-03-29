//
//  PokeVaultApp.swift
//  PokeVault
//
//  Created by Ayman Tauhid on 2025-03-28.
//

import SwiftUI
import FirebaseCore

@main
struct PokeVaultApp: App {
    @State private var isFirebaseInitialized = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isFirebaseInitialized {
                    ContentView()
                } else {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Loading...")
                            .padding()
                    }
                }
            }
            .task {
                do {
                    try await KeyConstants.loadAPIKeys()
                    isFirebaseInitialized = true
                } catch {
                    print("Error initializing Firebase: \(error.localizedDescription)")

                    isFirebaseInitialized = true
                }
            }
        }
    }
}
