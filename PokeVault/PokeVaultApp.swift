//
//  PokeVaultApp.swift
//  PokeVault
//
//  Created by Ayman Tauhid on 2025-03-28.
//

import SwiftUI
import FirebaseCore
import CoreData

@main
struct PokeVaultApp: App {
    @State private var isFirebaseInitialized = false
    @State private var initializationError: String? = nil
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isFirebaseInitialized {
                    ContentView()
                } else {
                    // Loading screen while Firebase initializes
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Loading...")
                            .padding()
                        
                        if let error = initializationError {
                            Text("Error: \(error)")
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding()
                        }
                    }
                }
            }
            .task {
                do {
                    // Load Firebase configuration from the JSON file
                    try await KeyConstants.loadAPIKeys()
                    isFirebaseInitialized = true
                } catch {
                    print("Error initializing Firebase: \(error.localizedDescription)")
                    initializationError = error.localizedDescription
                    
                    // Wait a moment then proceed to the app anyway
                    // This allows users to at least see the login screen
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isFirebaseInitialized = true
                    }
                }
            }
        }
    }
}

class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "PokeVault")
        container.loadPersistentStores { (_, error) in
            if let error = error {
                fatalError("Unresolved error \(error.localizedDescription)")
            }
        }
    }
}
