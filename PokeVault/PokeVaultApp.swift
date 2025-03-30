//
//  PokeVaultApp.swift
//  PokeVault
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

// App Delegate for Firebase initialization
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Initialize Firebase on the main thread
        FirebaseApp.configure()
        
        // Disable swizzling to avoid background thread issues
        // Add this to Info.plist:
        // <key>FirebaseAppDelegateProxyEnabled</key>
        // <false/>
        
        return true
    }
}

@main
struct PokeVaultApp: App {
<<<<<<< HEAD
    // Register app delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @State private var isAppReady = false
=======
    // Register the app delegate for UIKit lifecycle events
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @State private var isFirebaseInitialized = false
>>>>>>> main
    @State private var initializationError: String? = nil
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isAppReady {
                    ContentView()
                } else {
                    // Loading screen while app initializes
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
<<<<<<< HEAD
            .onAppear {
                // We don't need to initialize Firebase here since it's done in AppDelegate
                // Just set app as ready after a short delay to allow Firebase to fully initialize
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isAppReady = true
=======
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
>>>>>>> main
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
