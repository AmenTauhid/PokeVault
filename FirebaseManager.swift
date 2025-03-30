//
//  FirebaseManager.swift
//  PokeVault
//
//  Created by Omar Al dulaimi on 2025-03-29.
//


import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class FirebaseManager {
    static let shared = FirebaseManager()
    
    private init() {}
    
    func configure() {
        // Make sure Firebase is only configured once
        if FirebaseApp.app() == nil {
            // Ensure Firebase configuration happens on the main thread
            if Thread.isMainThread {
                FirebaseApp.configure()
            } else {
                DispatchQueue.main.sync {
                    FirebaseApp.configure()
                }
            }
        }
    }
    
    // Create a chat collection for a user
    func createChatCollection(userId: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        // Create an empty document in the chats subcollection to ensure it exists
        db.collection("users").document(userId).collection("chats").document("placeholder").setData([
            "created": Timestamp(date: Date()),
            "placeholder": true
        ]) { error in
            if let error = error {
                print("Error creating chat collection: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Chat collection created successfully for user \(userId)")
                completion(true)
            }
        }
    }
    
    // Create a chat between two users
    func createChat(betweenUser userId1: String, andUser userId2: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        
        // Create a chat document in the main chats collection
        let chatId = UUID().uuidString
        let chatRef = db.collection("chats").document(chatId)
        
        // Get user names for both participants
        let dispatchGroup = DispatchGroup()
        
        var user1Name = "Unknown User"
        var user2Name = "Unknown User"
        
        // Get first user's name
        dispatchGroup.enter()
        db.collection("users").document(userId1).getDocument { snapshot, error in
            if let data = snapshot?.data(), let name = data["name"] as? String {
                user1Name = name
            }
            dispatchGroup.leave()
        }
        
        // Get second user's name
        dispatchGroup.enter()
        db.collection("users").document(userId2).getDocument { snapshot, error in
            if let data = snapshot?.data(), let name = data["name"] as? String {
                user2Name = name
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            // Create the chat document
            let chatData: [String: Any] = [
                "participants": [userId1, userId2],
                "participantNames": [
                    userId1: user1Name,
                    userId2: user2Name
                ],
                "lastMessage": "",
                "lastMessageTimestamp": Timestamp(date: Date()),
                "createdAt": Timestamp(date: Date())
            ]
            
            chatRef.setData(chatData) { error in
                if let error = error {
                    print("Error creating chat: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                // Create references in each user's chats collection
                let batch = db.batch()
                
                // Reference for first user
                let user1ChatRef = db.collection("users").document(userId1).collection("chats").document(chatId)
                batch.setData([
                    "chatId": chatId,
                    "otherUserId": userId2,
                    "otherUserName": user2Name,
                    "lastMessage": "",
                    "lastMessageTimestamp": Timestamp(date: Date()),
                    "unreadCount": 0
                ], forDocument: user1ChatRef)
                
                // Reference for second user
                let user2ChatRef = db.collection("users").document(userId2).collection("chats").document(chatId)
                batch.setData([
                    "chatId": chatId,
                    "otherUserId": userId1,
                    "otherUserName": user1Name,
                    "lastMessage": "",
                    "lastMessageTimestamp": Timestamp(date: Date()),
                    "unreadCount": 0
                ], forDocument: user2ChatRef)
                
                batch.commit { error in
                    if let error = error {
                        print("Error creating chat references: \(error.localizedDescription)")
                        completion(nil)
                    } else {
                        print("Chat created successfully between \(userId1) and \(userId2)")
                        completion(chatId)
                    }
                }
            }
        }
    }
}
