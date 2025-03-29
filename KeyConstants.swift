//
//  KeyConstants.swift
//  PokeVault
//
//  Created by Omar Al dulaimi on 2025-03-28.
//


import Foundation
import FirebaseCore

enum KeyConstants {
    static func loadAPIKeys() async throws {
        let request = NSBundleResourceRequest(tags: ["APIKeys"])
        try await request.beginAccessingResources()
        
        // Check if we can access the GoogleService-Info.plist
        if let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            // Configure Firebase with the found plist file
            if FileManager.default.fileExists(atPath: filePath) {
                let firebaseOptions = FirebaseOptions(contentsOfFile: filePath)
                if let options = firebaseOptions {
                    if FirebaseApp.app() == nil {
                        FirebaseApp.configure(options: options)
                        print("Firebase configured successfully with GoogleService-Info.plist")
                    } else {
                        print("Firebase was already configured")
                    }
                } else {
                    print("Failed to create Firebase options from plist")
                    throw NSError(domain: "KeyConstants", code: 500,
                              userInfo: [NSLocalizedDescriptionKey: "Invalid Firebase configuration in plist"])
                }
            } else {
                print("GoogleService-Info.plist file does not exist at path")
                throw NSError(domain: "KeyConstants", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "GoogleService-Info.plist file not found"])
            }
        } else {
            print("GoogleService-Info.plist not found in bundle")
            throw NSError(domain: "KeyConstants", code: 404,
                      userInfo: [NSLocalizedDescriptionKey: "GoogleService-Info.plist not found in bundle"])
        }
        
        // End accessing resources once configuration is complete
        request.endAccessingResources()
    }
}
