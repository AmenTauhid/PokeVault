//
//  PokemonModels.swift
//  PokeVault
//
//  Created by Omar Al dulaimi on 2025-03-30.
//



import SwiftUI
import FirebaseFirestore

struct PokemonCard: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let imageUrl: String
    let releaseDate: String
    let dateAdded: Date
    
    init(id: String? = nil, name: String, imageUrl: String, releaseDate: String, dateAdded: Date = Date()) {
        self.id = id
        self.name = name
        self.imageUrl = imageUrl
        self.releaseDate = releaseDate
        self.dateAdded = dateAdded
    }
}

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
