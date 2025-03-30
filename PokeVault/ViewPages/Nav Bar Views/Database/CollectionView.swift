//
//  CollectionView.swift
//  PokeVault
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

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

class PokemonSearchViewModel: ObservableObject {
    @Published var cards: [SearchedPokemonCard] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
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

struct CollectionView: View {
    @StateObject private var firebaseManager = FirebaseManager()
    @State private var isSearchPagePresented = false
    @State private var showingLoginAlert = false
    @State private var selectedCard: PokemonCard?
    @State private var searchQuery = ""
    @State private var selectedType: String? = nil
    @State private var selectedYear: String? = nil
    
    var filteredCollection: [PokemonCard] {
        firebaseManager.collection.filter { card in
            (searchQuery.isEmpty || card.name.lowercased().contains(searchQuery.lowercased())) &&
            (selectedType == nil || card.types.contains(selectedType!)) &&
            (selectedYear == nil || card.releaseDate.contains(selectedYear!))
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack {
                    HStack {
                        TextField("Search...", text: $searchQuery)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white, lineWidth: 2))
                            .foregroundColor(Color.white)

                        
                        Button(action: addCardButtonTapped) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Card")
                            }
                            .padding(8)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Picker("Type", selection: $selectedType) {
                            Text("All Types").tag(nil as String?)
                            ForEach(uniqueTypes(), id: \.self) { type in
                                Text(type).tag(type as String?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())

                        Picker("Year", selection: $selectedYear) {
                            Text("All Years").tag(nil as String?)
                            ForEach(uniqueYears(), id: \.self) { year in
                                Text(year).tag(year as String?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding(.horizontal)
                }
                
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
                        ForEach(filteredCollection) { card in
                            Button(action: {
                                selectedCard = card
                            }) {
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
                                            .foregroundColor(Color.black)
                                        Text("Release Date: \(card.releaseDate)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        Text("Types: \(card.types.joined(separator: ", "))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text("Added: \(formattedDate(card.dateAdded))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.leading, 8)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color.white)
                        }
                        .onDelete(perform: deleteCards)
                    }
                    .background(Color.white)
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Your Collection")
            .sheet(item: $selectedCard) { card in
                CardDetailView(card: card)
            }
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
    
    private func uniqueTypes() -> [String] {
        Set(firebaseManager.collection.flatMap { $0.types }).sorted()
    }
    
    private func uniqueYears() -> [String] {
        Set(firebaseManager.collection.map { String($0.releaseDate.prefix(4)) }).sorted()
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
                    TextField("Search for a Pokémon card...", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(Color.white)
                    
                    Button(action: {
                        viewModel.searchCards(query: searchQuery)
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                }
                .padding()
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Searching...")
                        .foregroundColor(Color.white)
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage {
                    Spacer()
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
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
                                Text(card.name)
                                    .font(.headline)
                                    .foregroundColor(Color.black)
                                Text("Release Date: \(card.releaseDate)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("Types: \(card.types ?? [""])")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.leading, 8)
                            
                            Spacer()
                            
                            Button(action: {
                                addCardToCollection(card)
                            }) {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.red)
                                    .font(.title2)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                    .listStyle(PlainListStyle())
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
        .foregroundColor(Color.red)
    }
    
    private func addCardToCollection(_ card: SearchedPokemonCard) {
        let newCard = PokemonCard(
            name: card.name,
            imageUrl: card.imageUrl,
            releaseDate: card.releaseDate,
            types: card.types ?? [""],
            dateAdded: Date()
        )
        
        firebaseManager.addCard(newCard)
        lastAddedCard = card.name
        showingAddConfirmation = true
    }
}


struct CardDetailView: View {
    let card: PokemonCard
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                AsyncImage(url: URL(string: card.imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 400)
                } placeholder: {
                    ProgressView()
                }
                .padding()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(card.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color.red)
                    
                    Text("Release Date: \(card.releaseDate)")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    if !card.types.isEmpty {
                        Text("Types: \(card.types.joined(separator: ", "))")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Date Added: \(formattedDate(card.dateAdded))")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                .padding()
                Spacer()
            }
        }
        .navigationTitle("Card Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
