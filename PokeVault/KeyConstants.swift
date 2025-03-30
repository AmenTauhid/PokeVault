//
//  KeyConstants.swift
//  PokeVault
//
//  Created by Omar Al dulaimi on 2025-03-28.
//

import Foundation
import FirebaseCore

enum KeyConstants {
    // Firebase keys structure matching our JSON file
    struct FirebaseKeys: Decodable {
        let API_KEY: String
        let GCM_SENDER_ID: String
        let PROJECT_ID: String
        let STORAGE_BUCKET: String
        let BUNDLE_ID: String
        let GOOGLE_APP_ID: String
        let IS_ADS_ENABLED: Bool
        let IS_ANALYTICS_ENABLED: Bool
        let IS_APPINVITE_ENABLED: Bool
        let IS_GCM_ENABLED: Bool
        let IS_SIGNIN_ENABLED: Bool
    }
    
    static func loadAPIKeys() async throws {
        let request = NSBundleResourceRequest(tags: ["APIKeys"])
        try await request.beginAccessingResources()
        
        // Look for the APIKeys.json file
        if let url = Bundle.main.url(forResource: "APIKeys", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let firebaseKeys = try JSONDecoder().decode(FirebaseKeys.self, from: data)
                
                // Check if Firebase is already configured
                if FirebaseApp.app() == nil {
                    // Create Firebase options from the JSON data
                    let options = FirebaseOptions(
                        googleAppID: firebaseKeys.GOOGLE_APP_ID,
                        gcmSenderID: firebaseKeys.GCM_SENDER_ID
                    )
                    options.apiKey = firebaseKeys.API_KEY
                    options.projectID = firebaseKeys.PROJECT_ID
                    options.storageBucket = firebaseKeys.STORAGE_BUCKET
                    options.bundleID = firebaseKeys.BUNDLE_ID
                    
                    // Configure Firebase with these options
                    FirebaseApp.configure(options: options)
                    print("Firebase configured successfully with APIKeys.json")
                } else {
                    print("Firebase was already configured")
                }
            } catch {
                print("Error loading or parsing APIKeys.json: \(error.localizedDescription)")
                throw error
            }
        } else {
            let error = NSError(domain: "KeyConstants", code: 404,
                             userInfo: [NSLocalizedDescriptionKey: "APIKeys.json not found in bundle"])
            print(error.localizedDescription)
            throw error
        }
        
        // End accessing resources once configuration is complete
        request.endAccessingResources()
    }
}
