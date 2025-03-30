//
//  ChatService.swift
//  PokeVault
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class ChatService: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var messages: [Message] = []
    @Published var searchResults: [UserProfile] = []
    @Published var needsRefresh: Bool = false

    
    private let db = Firestore.firestore()
    private var chatListeners: [ListenerRegistration] = []
    private var messageListener: ListenerRegistration?
    
    // User profile structure
    struct UserProfile: Identifiable {
        let id: String
        let name: String
        let email: String
    }
    
    // Get current user ID
    var currentUserId: String {
        return Auth.auth().currentUser?.uid ?? ""
    }
    
    // Get current user name
    func getCurrentUserName(completion: @escaping (String) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion("")
            return
        }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists, let data = document.data() {
                let name = data["name"] as? String ?? "Unknown User"
                completion(name)
            } else {
                completion("Unknown User")
            }
        }
    }
    
    // Load all chats for current user
    func loadChats() {
        guard !currentUserId.isEmpty else { return }
        
        // Clear existing listeners first
        for listener in chatListeners {
            listener.remove()
        }
        chatListeners.removeAll()
        
        print("Loading chats for user: \(currentUserId)")
        
        // Get chats from the user's chat collection
        let userChatsRef = db.collection("users")
            .document(currentUserId)
            .collection("chats")
        
        let listener = userChatsRef.addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching chats: \(error.localizedDescription)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No chat documents found")
                return
            }
            
            print("Found \(documents.count) chat documents")
            
            // Transform chat references to Chat objects
            self.chats = documents.compactMap { document -> Chat? in  // explicitly specify return type as optional Chat
                // Skip placeholder document
                if let isPlaceholder = document.data()["placeholder"] as? Bool, isPlaceholder {
                    print("Skipping placeholder document")
                    return nil
                }
                
                guard let chatId = document.data()["chatId"] as? String,
                      let otherUserId = document.data()["otherUserId"] as? String,
                      let otherUserName = document.data()["otherUserName"] as? String else {
                    print("Missing required fields in chat document: \(document.documentID)")
                    return nil
                }
                
                let lastMessage = document.data()["lastMessage"] as? String ?? ""
                let timestamp = document.data()["lastMessageTimestamp"] as? Timestamp ?? Timestamp(date: Date())
                let unreadCount = document.data()["unreadCount"] as? Int ?? 0
                
                print("Processing chat: \(chatId) with \(otherUserName)")
                
                // Fetch the actual chat to get all participants
                let chatRef = self.db.collection("chats").document(chatId)
                
                // Add a separate listener for each chat to keep it updated
                let chatListener = chatRef.addSnapshotListener { chatSnapshot, chatError in
                    if let error = chatError {
                        print("Error listening to chat \(chatId): \(error.localizedDescription)")
                        return
                    }
                    
                    // Update the chat in the list
                    if let chatData = chatSnapshot?.data(),
                       let lastMessage = chatData["lastMessage"] as? String,
                       let timestamp = chatData["lastMessageTimestamp"] as? Timestamp {
                        
                        // Find and update the chat in our list
                        if let index = self.chats.firstIndex(where: { $0.id == chatId }) {
                            // Update only what changed
                            self.chats[index].lastMessage = lastMessage
                            self.chats[index].lastMessageTimestamp = timestamp.dateValue()
                            
                            // Sort chats after update
                            self.chats.sort { $0.lastMessageTimestamp > $1.lastMessageTimestamp }
                        }
                    }
                }
                
                self.chatListeners.append(chatListener)
                
                // Create a Chat object from the reference
                return Chat(
                    id: chatId,
                    participants: [self.currentUserId, otherUserId],
                    participantNames: [
                        self.currentUserId: "You",
                        otherUserId: otherUserName
                    ],
                    lastMessage: lastMessage,
                    lastMessageTimestamp: timestamp.dateValue()
                )
            }
            
            // Sort chats by last message timestamp
            self.chats.sort { $0.lastMessageTimestamp > $1.lastMessageTimestamp }
            print("Processed \(self.chats.count) valid chats")
        }
        
        chatListeners.append(listener)
    }
    
    // Load messages for a specific chat
    func loadMessages(chatId: String) {
        // Remove any existing listener
        messageListener?.remove()
        
        print("Loading messages for chat: \(chatId)")
        
        let messagesRef = db.collection("chats").document(chatId).collection("messages")
            .order(by: "timestamp", descending: false)
        
        messageListener = messagesRef.addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching messages: \(error.localizedDescription)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No messages found")
                self.messages = []
                return
            }
            
            print("Found \(documents.count) messages")
            
            self.messages = documents.compactMap { document in
                let data = document.data()
                guard let id = data["id"] as? String,
                      let senderId = data["senderId"] as? String,
                      let senderName = data["senderName"] as? String,
                      let receiverId = data["receiverId"] as? String,
                      let content = data["content"] as? String,
                      let timestamp = data["timestamp"] as? Timestamp else {
                    print("Missing required fields in message: \(document.documentID)")
                    return nil
                }
                
                return Message(
                    id: id,
                    senderId: senderId,
                    senderName: senderName,
                    receiverId: receiverId,
                    content: content,
                    timestamp: timestamp.dateValue()
                )
            }
            
            // Mark messages as read if they're not from the current user
            self.markMessagesAsRead(chatId: chatId)
        }
    }
    
    // Mark messages as read
    private func markMessagesAsRead(chatId: String) {
        guard !currentUserId.isEmpty else { return }
        
        // Update the unread count in the user's chat reference
        let userChatRef = db.collection("users")
            .document(currentUserId)
            .collection("chats")
            .document(chatId)
        
        userChatRef.updateData([
            "unreadCount": 0
        ]) { error in
            if let error = error {
                print("Error marking messages as read: \(error.localizedDescription)")
            } else {
                print("Messages marked as read for chat: \(chatId)")
            }
        }
    }
    
    // Send a message
    func sendMessage(chatId: String, receiverId: String, content: String, completion: @escaping (Bool) -> Void) {
        guard !currentUserId.isEmpty, !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("Invalid user ID or empty message")
            completion(false)
            return
        }
        
        print("Sending message to \(receiverId) in chat \(chatId)")
        
        getCurrentUserName { [weak self] senderName in
            guard let self = self else { return }
            
            let message = Message(
                senderId: self.currentUserId,
                senderName: senderName,
                receiverId: receiverId,
                content: content
            )
            
            let batch = self.db.batch()
            
            // Add message to the chat's messages subcollection
            let messageRef = self.db.collection("chats").document(chatId).collection("messages").document(message.id)
            batch.setData(message.toFirestoreData(), forDocument: messageRef)
            
            // Update the chat document with last message info
            let chatRef = self.db.collection("chats").document(chatId)
            batch.updateData([
                "lastMessage": content,
                "lastMessageTimestamp": Timestamp(date: message.timestamp)
            ], forDocument: chatRef)
            
            // Update the sender's chat reference
            let senderChatRef = self.db.collection("users")
                .document(self.currentUserId)
                .collection("chats")
                .document(chatId)
            
            batch.updateData([
                "lastMessage": content,
                "lastMessageTimestamp": Timestamp(date: message.timestamp)
            ], forDocument: senderChatRef)
            
            // Update the receiver's chat reference and increment unread count
            let receiverChatRef = self.db.collection("users")
                .document(receiverId)
                .collection("chats")
                .document(chatId)
            
            // Get the current unread count
            receiverChatRef.getDocument { document, error in
                if let document = document, document.exists {
                    let currentUnreadCount = document.data()?["unreadCount"] as? Int ?? 0
                    
                    // Update the receiver's chat reference
                    batch.updateData([
                        "lastMessage": content,
                        "lastMessageTimestamp": Timestamp(date: message.timestamp),
                        "unreadCount": currentUnreadCount + 1
                    ], forDocument: receiverChatRef)
                    
                    // Commit all changes
                    batch.commit { error in
                        if let error = error {
                            print("Error sending message: \(error.localizedDescription)")
                            completion(false)
                        } else {
                            print("Message sent successfully")
                            completion(true)
                        }
                    }
                } else {
                    // If the document doesn't exist, create it
                    self.getCurrentUserName { currentUserName in
                        receiverChatRef.setData([
                            "chatId": chatId,
                            "otherUserId": self.currentUserId,
                            "otherUserName": currentUserName,
                            "lastMessage": content,
                            "lastMessageTimestamp": Timestamp(date: message.timestamp),
                            "unreadCount": 1
                        ]) { error in
                            if let error = error {
                                print("Error creating receiver chat reference: \(error.localizedDescription)")
                                completion(false)
                            } else {
                                // Now commit the other changes
                                batch.commit { error in
                                    if let error = error {
                                        print("Error sending message: \(error.localizedDescription)")
                                        completion(false)
                                    } else {
                                        print("Message sent successfully with new receiver chat reference")
                                        completion(true)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Create a new chat
    func createChat(with userId: String, userName: String, completion: @escaping (String) -> Void) {
        guard !currentUserId.isEmpty, currentUserId != userId else {
            print("Invalid user ID or trying to chat with self")
            completion("")
            return
        }
        
        print("Creating chat with user: \(userName) (\(userId))")
        
        // Check if a chat already exists with this user
        db.collection("users")
            .document(currentUserId)
            .collection("chats")
            .whereField("otherUserId", isEqualTo: userId)
            .getDocuments { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error checking existing chats: \(error.localizedDescription)")
                    completion("")
                    return
                }
                
                if let documents = querySnapshot?.documents, let firstDoc = documents.first {
                    // Chat already exists, return its ID
                    if let chatId = firstDoc.data()["chatId"] as? String {
                        print("Chat already exists with ID: \(chatId)")
                        completion(chatId)
                        return
                    }
                }
                
                print("No existing chat found, creating new chat")
                
                // No existing chat found, create a new one
                self.getCurrentUserName { currentUserName in
                    // Create a chat document in the main chats collection
                    let chatId = UUID().uuidString
                    let chatRef = self.db.collection("chats").document(chatId)
                    
                    // Create the chat document
                    let chatData: [String: Any] = [
                        "participants": [self.currentUserId, userId],
                        "participantNames": [
                            self.currentUserId: currentUserName,
                            userId: userName
                        ],
                        "lastMessage": "",
                        "lastMessageTimestamp": Timestamp(date: Date()),
                        "createdAt": Timestamp(date: Date())
                    ]
                    
                    chatRef.setData(chatData) { error in
                        if let error = error {
                            print("Error creating chat: \(error.localizedDescription)")
                            completion("")
                            return
                        }
                        
                        // Create references in each user's chats collection
                        let batch = self.db.batch()
                        
                        // Reference for current user
                        let userChatRef = self.db.collection("users")
                            .document(self.currentUserId)
                            .collection("chats")
                            .document(chatId)
                        
                        batch.setData([
                            "chatId": chatId,
                            "otherUserId": userId,
                            "otherUserName": userName,
                            "lastMessage": "",
                            "lastMessageTimestamp": Timestamp(date: Date()),
                            "unreadCount": 0
                        ], forDocument: userChatRef)
                        
                        // Reference for other user
                        let otherUserChatRef = self.db.collection("users")
                            .document(userId)
                            .collection("chats")
                            .document(chatId)
                        
                        batch.setData([
                            "chatId": chatId,
                            "otherUserId": self.currentUserId,
                            "otherUserName": currentUserName,
                            "lastMessage": "",
                            "lastMessageTimestamp": Timestamp(date: Date()),
                            "unreadCount": 0
                        ], forDocument: otherUserChatRef)
                        
                        batch.commit { error in
                            if let error = error {
                                print("Error creating chat references: \(error.localizedDescription)")
                                completion("")
                            } else {
                                print("Chat created successfully with ID: \(chatId)")
                                completion(chatId)
                            }
                        }
                    }
                }
            }
    }
    
    // Helper method to ensure user data is properly stored
    func ensureUserDataInFirestore(completion: @escaping (Bool) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user is logged in")
            completion(false)
            return
        }
        
        print("Ensuring user data is in Firestore for: \(currentUser.uid)")
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(currentUser.uid)
        
        userRef.getDocument { document, error in
            if let error = error {
                print("Error checking user document: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let document = document, document.exists, let _ = document.data()?["email"] as? String {
                // User data already exists with email field
                print("User document already exists with email field")
                completion(true)
            } else {
                // Create or update user document with email
                var userData: [String: Any] = [
                    "email": currentUser.email ?? "",
                    "searchableEmail": (currentUser.email ?? "").lowercased(), // For easier searching
                    "lastUpdated": FieldValue.serverTimestamp()
                ]
                
                // Add name if available
                if let displayName = currentUser.displayName, !displayName.isEmpty {
                    userData["name"] = displayName
                    userData["searchableName"] = displayName.lowercased()
                } else {
                    // Use email as name if no display name
                    let emailName = currentUser.email?.components(separatedBy: "@").first ?? "User"
                    userData["name"] = emailName
                    userData["searchableName"] = emailName.lowercased()
                }
                
                userRef.setData(userData, merge: true) { error in
                    if let error = error {
                        print("Error saving user data: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("Successfully saved user data with email")
                        
                        // Create chats subcollection with placeholder
                        self.createChatCollectionIfNeeded(for: currentUser.uid) { success in
                            completion(success)
                        }
                    }
                }
            }
        }
    }
    
    // Create a placeholder document in chats subcollection
    private func createChatCollectionIfNeeded(for userId: String, completion: @escaping (Bool) -> Void) {
        let chatCollectionRef = db.collection("users").document(userId).collection("chats")
        
        // Check if collection already has documents
        chatCollectionRef.limit(to: 1).getDocuments { snapshot, error in
            if let error = error {
                print("Error checking chats collection: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let snapshot = snapshot, !snapshot.isEmpty {
                // Collection already has at least one document
                print("Chats collection already exists")
                completion(true)
                return
            }
            
            // Create placeholder document
            let placeholderRef = chatCollectionRef.document("placeholder")
            placeholderRef.setData([
                "placeholder": true,
                "created": Timestamp(date: Date())
            ]) { error in
                if let error = error {
                    print("Error creating placeholder: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Created placeholder document in chats collection")
                    completion(true)
                }
            }
        }
    }
    
    // Search for users
    func searchUsers(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        print("Searching for users with query: \(query)")
        
        let usersRef = db.collection("users")
        let lowercaseQuery = query.lowercased()
        
        // First try to search by exact email
        usersRef.whereField("email", isEqualTo: query).getDocuments { [weak self] querySnapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error searching by email: \(error.localizedDescription)")
                self.searchResults = []
                return
            }
            
            if let documents = querySnapshot?.documents, !documents.isEmpty {
                print("Found \(documents.count) users by exact email")
                self.processUserSearchResults(documents)
            } else {
                // Try with lowercase email
                usersRef.whereField("searchableEmail", isEqualTo: lowercaseQuery).getDocuments { [weak self] querySnapshot, error in
                    guard let self = self else { return }
                    
                    if let documents = querySnapshot?.documents, !documents.isEmpty {
                        print("Found \(documents.count) users by lowercase email")
                        self.processUserSearchResults(documents)
                    } else {
                        // Try searching by name
                        self.searchByName(query: query)
                    }
                }
            }
        }
    }
    
    // Helper method to search by name
    private func searchByName(query: String) {
        print("Searching by name: \(query)")
        
        let usersRef = db.collection("users")
        let lowercaseQuery = query.lowercased()
        
        // Try with searchableName field first
        usersRef.whereField("searchableName", isGreaterThanOrEqualTo: lowercaseQuery)
               .whereField("searchableName", isLessThanOrEqualTo: lowercaseQuery + "\u{f8ff}")
               .getDocuments { [weak self] querySnapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error searching by searchableName: \(error.localizedDescription)")
                self.searchResults = []
                return
            }
            
            if let documents = querySnapshot?.documents, !documents.isEmpty {
                print("Found \(documents.count) users by searchableName")
                self.processUserSearchResults(documents)
            } else {
                // Try with regular name field
                usersRef.whereField("name", isGreaterThanOrEqualTo: query)
                       .whereField("name", isLessThanOrEqualTo: query + "\u{f8ff}")
                       .getDocuments { [weak self] querySnapshot, error in
                    guard let self = self else { return }
                    
                    if let documents = querySnapshot?.documents {
                        print("Found \(documents.count) users by regular name")
                        self.processUserSearchResults(documents)
                    } else {
                        print("No users found by any search method")
                        self.searchResults = []
                    }
                }
            }
        }
    }
    
    private func processUserSearchResults(_ documents: [QueryDocumentSnapshot]) {
        print("Processing \(documents.count) user search results")
        
        self.searchResults = documents.compactMap { document in
            let data = document.data()
            
            // Skip the current user
            if document.documentID == self.currentUserId {
                print("Skipping current user: \(document.documentID)")
                return nil
            }
            
            // Print all available fields for debugging
            print("User document data: \(data)")
            
            let email = data["email"] as? String ?? ""
            let name = data["name"] as? String ?? "Unknown User"
            
            // Use email as fallback if name is empty
            let displayName = name.isEmpty ? email.components(separatedBy: "@").first ?? "Unknown User" : name
            
            return UserProfile(id: document.documentID, name: displayName, email: email)
        }
        
        print("Processed search results: \(self.searchResults.count) users found")
    }
    
    // Clean up listeners when done
    func cleanup() {
        for listener in chatListeners {
            listener.remove()
        }
        chatListeners.removeAll()
        
        messageListener?.remove()
        messageListener = nil
        
        print("Cleaned up all listeners")
    }
}
