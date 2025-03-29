//
//  CollectionView.swift
//  PokeVault
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

// Firebase Model
struct PokemonCard: Identifiable, Codable {
    @DocumentID var id: String?  // Firestore document ID
    let name: String
    let imageUrl: String
    let releaseDate: String
    let dateAdded: Date
    
    // Custom init to set default dateAdded
    init(id: String? = nil, name: String, imageUrl: String, releaseDate: String, dateAdded: Date = Date()) {
        self.id = id
        self.name = name
        self.imageUrl = imageUrl
        self.releaseDate = releaseDate
        self.dateAdded = dateAdded
    }
}

// Struct for search results
struct SearchedPokemonCard {
    let name: String
    let imageUrl: String
    let releaseDate: String
}

struct PokemonResponse: Codable {
    let data: [PokemonData]
}

struct PokemonData: Codable {
    let name: String
    let images: PokemonImages
    let set: PokemonSet
}

struct PokemonImages: Codable {
    let small: String
}

struct PokemonSet: Codable {
    let releaseDate: String
}

class FirebaseManager: ObservableObject {
    @Published var collection: [PokemonCard] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var userId: String? { Auth.auth().currentUser?.uid }
    private var listener: ListenerRegistration?
    
    // Initialize and setup listener
    init() {
        setupAuthListener()
    }
    
    // Listen for auth state changes and fetch collection when user is logged in
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
    
    // Clear listener when not needed
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
        
        // Create data dictionary with all card fields including dateAdded
        let cardData: [String: Any] = [
            "name": card.name,
            "imageUrl": card.imageUrl,
            "releaseDate": card.releaseDate,
            "dateAdded": Timestamp(date: card.dateAdded)
        ]
        
        collectionRef.addDocument(data: cardData) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("Error adding card: \(error.localizedDescription)")
                    self?.errorMessage = "Failed to add card: \(error.localizedDescription)"
                } else {
                    print("Card successfully added to Firestore!")
                    // No need to manually fetch again as we're using a listener
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
        
        // Remove any existing listener
        removeListener()
        
        let collectionRef = db.collection("users").document(userId).collection("pokemon_cards")
            .order(by: "dateAdded", descending: true)
        
        // Setup a real-time listener
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
        
        // Get the cards to delete from the indexSet
        let cardsToDelete = indexSet.map { collection[$0] }
        
        // Delete each card
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

// Search ViewModel
class PokemonSearchViewModel: ObservableObject {
    @Published var cards: [SearchedPokemonCard] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Your API key should be stored securely, not hardcoded
    private let apiKey = "YOUR-API-KEY"

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
                            releaseDate: card.set.releaseDate
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

// Main Collection View
struct CollectionView: View {
    @StateObject private var firebaseManager = FirebaseManager()
    @State private var isSearchPagePresented = false
    @State private var showingLoginAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                if firebaseManager.isLoading {
                    ProgressView("Loading your collection...")
                } else if firebaseManager.collection.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Your collection is empty")
                            .font(.title2)
                        Text("Tap 'Add Card' to search for Pokémon cards")
                            .foregroundColor(.gray)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(firebaseManager.collection) { card in
                            HStack {
                                AsyncImage(url: URL(string: card.imageUrl)) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 70, height: 100)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(card.name).font(.headline)
                                    Text("Release Date: \(card.releaseDate)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Text("Added: \(formattedDate(card.dateAdded))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.leading, 8)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteCards)
                    }
                    .listStyle(InsetGroupedListStyle())
                }
                
                Button(action: addCardButtonTapped) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Card")
                    }
                    .frame(minWidth: 200)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.bottom)
            }
            .navigationTitle("Your Collection")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshCollection) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .alert(isPresented: $showingLoginAlert) {
                Alert(
                    title: Text("Not Logged In"),
                    message: Text("You need to login first to manage your collection."),
                    primaryButton: .default(Text("Login"), action: {
                        // Handle login here
                    }),
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $isSearchPagePresented) {
                SearchPage(firebaseManager: firebaseManager)
            }
            .onAppear {
                if Auth.auth().currentUser == nil {
                    showingLoginAlert = true
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func addCardButtonTapped() {
        if Auth.auth().currentUser != nil {
            isSearchPagePresented = true
        } else {
            showingLoginAlert = true
        }
    }
    
    private func refreshCollection() {
        firebaseManager.fetchCollection()
    }
    
    private func deleteCards(at offsets: IndexSet) {
        firebaseManager.deleteCard(at: offsets)
    }
}

// Search Page
struct SearchPage: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchQuery = ""
    @StateObject private var viewModel = PokemonSearchViewModel()
    @ObservedObject var firebaseManager: FirebaseManager
    @State private var showingAddConfirmation = false
    @State private var lastAddedCard: String?
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Search for a Pokémon card", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        viewModel.searchCards(query: searchQuery)
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .padding()
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage {
                    Spacer()
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                            .padding()
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    List(viewModel.cards, id: \.name) { card in
                        HStack {
                            AsyncImage(url: URL(string: card.imageUrl)) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 70, height: 100)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(card.name).font(.headline)
                                Text("Release Date: \(card.releaseDate)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.leading, 8)
                            
                            Spacer()
                            
                            Button(action: {
                                addCardToCollection(card)
                            }) {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Search Cards")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingAddConfirmation) {
                Alert(
                    title: Text("Card Added"),
                    message: Text("\(lastAddedCard ?? "Card") added to your collection."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func addCardToCollection(_ card: SearchedPokemonCard) {
        let newCard = PokemonCard(
            name: card.name,
            imageUrl: card.imageUrl,
            releaseDate: card.releaseDate,
            dateAdded: Date()
        )
        
        firebaseManager.addCard(newCard)
        lastAddedCard = card.name
        showingAddConfirmation = true
    }
}
