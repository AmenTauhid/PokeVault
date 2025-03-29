//
//  PokeVaultApp.swift
//  PokeVault
//
//  Created by Ayman Tauhid on 2025-03-28.
//

import SwiftUI
import FirebaseCore
import CoreData
import Firebase

// Add the UIApplicationDelegate implementation here
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Configure Firebase directly here
        FirebaseApp.configure()
        return true
    }
}

@main
struct PokeVaultApp: App {
    // Register the app delegate for UIKit lifecycle events
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
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
                    // Load your API keys if needed, but Firebase will be already configured via AppDelegate
                    try await KeyConstants.loadAPIKeys()
                    isFirebaseInitialized = true
                } catch {
                    print("Error loading API keys: \(error.localizedDescription)")
                    initializationError = error.localizedDescription
                    
                    // Wait a moment then proceed to the app anyway
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
