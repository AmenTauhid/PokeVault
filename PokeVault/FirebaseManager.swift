//
//  FirebaseManager.swift
//  PokeVault
//
import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

// Pokemon-related structures
struct PokemonCard: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let imageUrl: String
    let releaseDate: String
    let dateAdded: Date
    let types: [String]
    
    init(id: String? = nil, name: String, imageUrl: String, releaseDate: String, types: [String], dateAdded: Date = Date()) {
        self.id = id
        self.name = name
        self.imageUrl = imageUrl
        self.releaseDate = releaseDate
        self.types = types
        self.dateAdded = dateAdded
    }
}

struct SearchedPokemonCard {
    let name: String
    let imageUrl: String
    let releaseDate: String
    let types: [String]?
}

struct PokemonResponse: Codable {
    let data: [PokemonData]
}

struct PokemonData: Codable {
    let name: String
    let images: PokemonImages
    let set: PokemonSet
    let types: [String]?
    
    enum CodingKeys: String, CodingKey {
        case name
        case images
        case set
        case types
    }
}

struct PokemonImages: Codable {
    let small: String
}

struct PokemonSet: Codable {
    let releaseDate: String
}



// Main Firebase Service class - handles core Firebase operations
class FirebaseService {
    static let shared = FirebaseService()
    
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

// Firebase Manager for Pokemon cards
class FirebaseManager: ObservableObject {
    @Published var collection: [PokemonCard] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var userId: String? { Auth.auth().currentUser?.uid }
    private var listener: ListenerRegistration?
    
    init() {
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            if user != nil {
                self?.fetchCollection()
            } else {
                self?.collection = []
                self?.removeListener()
            }
        }
    }
    
    private func removeListener() {
        listener?.remove()
        listener = nil
    }
    
    func addCard(_ card: PokemonCard) {
        guard let userId = userId else {
            self.errorMessage = "User not authenticated. Please log in."
            return
        }
        
        isLoading = true
        
        let collectionRef = db.collection("users").document(userId).collection("pokemon_cards")
        
        let cardData: [String: Any] = [
            "name": card.name,
            "imageUrl": card.imageUrl,
            "releaseDate": card.releaseDate,
            "dateAdded": Timestamp(date: card.dateAdded),
            "types": card.types
        ]
        
        collectionRef.addDocument(data: cardData) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("Error adding card: \(error.localizedDescription)")
                    self?.errorMessage = "Failed to add card: \(error.localizedDescription)"
                } else {
                    print("Card successfully added to Firestore!")
                }
            }
        }
    }
    
    func fetchCollection() {
        guard let userId = userId else {
            self.errorMessage = "User not authenticated. Please log in."
            return
        }
        
        isLoading = true
        
        removeListener()
        
        let collectionRef = db.collection("users").document(userId).collection("pokemon_cards")
            .order(by: "dateAdded", descending: true)
        
        listener = collectionRef.addSnapshotListener { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("Error fetching collection: \(error.localizedDescription)")
                    self?.errorMessage = "Failed to fetch collection: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self?.collection = documents.compactMap { doc -> PokemonCard? in
                    try? doc.data(as: PokemonCard.self)
                }
            }
        }
    }
    
    func deleteCard(at indexSet: IndexSet) {
        guard let userId = userId else { return }

        let cardsToDelete = indexSet.map { collection[$0] }
        
        for card in cardsToDelete {
            if let id = card.id {
                let docRef = db.collection("users").document(userId).collection("pokemon_cards").document(id)
                docRef.delete { error in
                    if let error = error {
                        print("Error removing card: \(error.localizedDescription)")
                    } else {
                        print("Card successfully removed!")
                    }
                }
            }
        }
    }
    
    deinit {
        removeListener()
    }
}

// View model for Pokemon card search
class PokemonSearchViewModel: ObservableObject {
    @Published var cards: [SearchedPokemonCard] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let apiKey = "YOUR-API-KEY" // Replace with your actual API key

    func searchCards(query: String) {
        guard !query.isEmpty else {
            cards = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let formattedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = URL(string: "https://api.pokemontcg.io/v2/cards?q=name:\"\(formattedQuery)\"")!
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received from server"
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(PokemonResponse.self, from: data)
                    self?.cards = response.data.map { card in
                        SearchedPokemonCard(
                            name: card.name,
                            imageUrl: card.images.small,
                            releaseDate: card.set.releaseDate,
                            types: card.types
                        )
                    }
                    
                    if response.data.isEmpty {
                        self?.errorMessage = "No results found for '\(query)'"
                    }
                } catch {
                    print("Error parsing data: \(error.localizedDescription)")
                    self?.errorMessage = "Error parsing data: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

// Extension to the FirebaseService for convenience methods
extension FirebaseService {
    // Helper method to create a chat collection for a user
    func createChatCollection(for userId: String, completion: @escaping (Bool) -> Void) {
        createChatCollection(userId: userId, completion: completion)
    }
    
    // Helper method to get the current user ID
    var currentUserId: String {
        return Auth.auth().currentUser?.uid ?? ""
    }
    
    // Helper method to get a reference to the Firestore database
    var db: Firestore {
        return Firestore.firestore()
    }
}
