//
//  PokeVaultApp.swift
//  PokeVault
//

import SwiftUI
import FirebaseCore
import CoreData

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
    // Register app delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @State private var isAppReady = false
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
            .onAppear {
                // We don't need to initialize Firebase here since it's done in AppDelegate
                // Just set app as ready after a short delay to allow Firebase to fully initialize
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isAppReady = true
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
