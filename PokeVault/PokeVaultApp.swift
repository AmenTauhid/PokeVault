//
//  PokeVaultApp.swift
//  PokeVault
//

import SwiftUI
import CoreData

@main
struct PokeVaultApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            LandingView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
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
