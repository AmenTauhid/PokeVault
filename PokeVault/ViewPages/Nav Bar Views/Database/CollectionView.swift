//
//  CollectionView.swift
//  PokeVault
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct CollectionView: View {
    @ObservedObject private var pokemonManager = PokemonManager()
    @State private var isSearchPagePresented = false
    @State private var showingLoginAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                if pokemonManager.isLoading {
                    ProgressView("Loading your collection...")
                } else if pokemonManager.collection.isEmpty {
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
                        ForEach(pokemonManager.collection) { card in
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
                    }),
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $isSearchPagePresented) {
                SearchPage(pokemonManager: pokemonManager)
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
        pokemonManager.fetchCollection()
    }
    
    private func deleteCards(at offsets: IndexSet) {
        pokemonManager.deleteCard(at: offsets)
    }
}

struct SearchPage: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchQuery = ""
    @StateObject private var viewModel = PokemonSearchViewModel()
    @ObservedObject var pokemonManager: PokemonManager
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
        
        pokemonManager.addCard(newCard)
        lastAddedCard = card.name
        showingAddConfirmation = true
    }
}
