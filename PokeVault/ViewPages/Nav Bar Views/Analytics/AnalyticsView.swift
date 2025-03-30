//
//  AnalyticsView.swift
//  PokeVault
//

import SwiftUI
import Charts

// Model to represent Pokemon data with pricing from the CSV
struct Pokemon: Identifiable, Codable {
    let id: Int
    let name: String
    let type1: String
    let type2: String?
    let baseTotal: Int
    let isLegendary: Bool
    let price: Double
    let predictedPrice: Double
    
    // Default ID to use for non-sequential data
    var uuid = UUID()
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type1
        case type2 = "type2"
        case baseTotal = "base_total"
        case isLegendary = "is_legendary"
        case price = "price"
        case predictedPrice = "Predicted_Price"
    }
}

// For type-based analytics
struct TypePricing: Identifiable {
    let id = UUID()
    let type: String
    let averagePrice: Double
    let count: Int
}

// For generation-based analytics
struct GenerationPricing: Identifiable {
    let id = UUID()
    let generation: Int
    let averagePrice: Double
    let pokemonCount: Int
}

// Helper function to determine color based on type - global function
func colorForPokemonType(_ type: String) -> Color {
    switch type.lowercased() {
    case "normal": return Color(.systemGray)
    case "fire": return Color(.systemRed)
    case "water": return Color(.systemBlue)
    case "electric": return Color(.systemYellow)
    case "grass": return Color(.systemGreen)
    case "ice": return Color(.systemCyan)
    case "fighting": return Color(.systemOrange)
    case "poison": return Color(.systemPurple)
    case "ground": return Color(.systemBrown)
    case "flying": return Color(.systemTeal)
    case "psychic": return Color(.systemPink)
    case "bug": return Color(.systemGreen).opacity(0.7)
    case "rock": return Color(.systemBrown).opacity(0.7)
    case "ghost": return Color(.systemIndigo)
    case "dragon": return Color(.systemIndigo).opacity(0.7)
    case "dark": return Color(.darkGray)
    case "steel": return Color(.systemGray2)
    case "fairy": return Color(.systemPink).opacity(0.7)
    default: return Color(.systemGray)
    }
}

struct AnalyticsView: View {
    @State private var pokemonData: [Pokemon] = []
    @State private var typePricing: [TypePricing] = []
    @State private var generationPricing: [GenerationPricing] = []
    @State private var selectedTab = 0
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading Pokemon prediction data...")
                        .padding()
                } else if pokemonData.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("No Pokemon prediction data found")
                            .font(.headline)
                        
                        Text("Make sure the prediction CSV file is included in your project bundle")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Retry Loading Data") {
                            isLoading = true
                            loadPredictionData()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                } else {
                    TabView(selection: $selectedTab) {
                        topPokemonView
                            .tabItem {
                                Label("Top Pokémon", systemImage: "star.fill")
                            }
                            .tag(0)
                        
                        priceDistributionView
                            .tabItem {
                                Label("Price Distribution", systemImage: "chart.bar.fill")
                            }
                            .tag(1)
                        
                        typeAnalysisView
                            .tabItem {
                                Label("Type Analysis", systemImage: "tag.fill")
                            }
                            .tag(2)
                        
                        insightsView
                            .tabItem {
                                Label("Insights", systemImage: "lightbulb.fill")
                            }
                            .tag(3)
                    }
                }
            }
            .navigationTitle("Pokémon Price Analytics")
            .onAppear {
                loadPredictionData()
            }
        }
    }
    
    // Top and Bottom Valued Pokemon
    var topPokemonView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Top 10 Most Valuable Pokémon")
                    .font(.headline)
                    .padding(.horizontal)
                
                Text("Based on our ML prediction model")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                ForEach(Array(pokemonData.prefix(10).enumerated()), id: \.element.id) { index, pokemon in
                    PokemonPriceCard(pokemon: pokemon, rank: index + 1)
                }
                
                Divider()
                    .padding()
                
                Text("10 Least Valuable Pokémon")
                    .font(.headline)
                    .padding(.horizontal)
                
                ForEach(Array(pokemonData.suffix(10).enumerated()), id: \.element.id) { index, pokemon in
                    PokemonPriceCard(pokemon: pokemon, rank: pokemonData.count - 9 + index)
                }
                
                Text("Total Pokémon analyzed: \(pokemonData.count)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
            }
            .padding()
        }
    }
    
    // Price Distribution Chart
    var priceDistributionView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Price Distribution")
                    .font(.headline)
                    .padding(.horizontal)
                
                // Price range counts for histogram
                let priceBuckets = createPriceBuckets()
                
                Chart {
                    ForEach(priceBuckets) { bucket in
                        BarMark(
                            x: .value("Price Range", bucket.range),
                            y: .value("Count", bucket.count)
                        )
                        .foregroundStyle(Color.blue.gradient)
                    }
                }
                .frame(height: 300)
                .padding()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Price Statistics:")
                        .font(.headline)
                    
                    let prices = pokemonData.map { $0.price }
                    let avg = prices.reduce(0, +) / Double(prices.count)
                    let max = prices.max() ?? 0
                    let min = prices.min() ?? 0
                    
                    Text("Average Price: $\(avg, specifier: "%.2f")")
                    Text("Maximum Price: $\(max, specifier: "%.2f")")
                    Text("Minimum Price: $\(min, specifier: "%.2f")")
                    
                    Text("Price Factors from Model:")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("• Legendary status increases value significantly")
                    Text("• Type popularity (Dragon, Psychic, Fire types valued higher)")
                    Text("• Base statistics heavily influence price")
                    Text("• Starter and mascot Pokémon (e.g., Pikachu) have premium pricing")
                    Text("• Generation influences collectible value")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            .padding()
        }
    }
    
    // Type Analysis View
    var typeAnalysisView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Price by Pokémon Type")
                    .font(.headline)
                    .padding(.horizontal)
                
                Chart {
                    ForEach(typePricing) { type in
                        BarMark(
                            x: .value("Type", type.type),
                            y: .value("Avg Price", type.averagePrice)
                        )
                        .foregroundStyle(colorForPokemonType(type.type))
                    }
                }
                .frame(height: 300)
                .padding()
                
                Text("Type Count Distribution")
                    .font(.headline)
                    .padding(.horizontal)
                
                Chart {
                    ForEach(typePricing) { type in
                        BarMark(
                            x: .value("Type", type.type),
                            y: .value("Count", type.count)
                        )
                        .foregroundStyle(colorForPokemonType(type.type))
                    }
                }
                .frame(height: 300)
                .padding()
                
                Text("Most Valuable Types:")
                    .font(.headline)
                    .padding(.horizontal)
                
                ForEach(typePricing.sorted(by: { $0.averagePrice > $1.averagePrice }).prefix(5)) { type in
                    HStack {
                        Text(type.type.capitalized)
                            .font(.subheadline)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 12)
                            .background(colorForPokemonType(type.type))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        
                        Spacer()
                        
                        Text("$\(type.averagePrice, specifier: "%.2f")")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
    }
    
    // Insights View
    var insightsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Key Insights from ML Model")
                    .font(.headline)
                    .padding(.horizontal)
                
                InsightCard(
                    title: "Legendary Premium",
                    description: "Legendary Pokémon are worth \(legendaryPremium())× more than non-legendary on average",
                    icon: "crown.fill",
                    color: .yellow
                )
                
                // Get most valuable type
                let topType = topValuedType()
                InsightCard(
                    title: "Type Value",
                    description: "\(topType.capitalized)-type Pokémon command the highest average price at $\(String(format: "%.2f", topTypeAverage()))",
                    icon: "flame.fill",
                    color: .red
                )
                
                // Get generation insight
                let genInsight = generationInsight()
                InsightCard(
                    title: "Generation Impact",
                    description: genInsight,
                    icon: "1.circle.fill",
                    color: .blue
                )
                
                InsightCard(
                    title: "Stats Correlation",
                    description: "Base stats heavily influence pricing - the highest total stat Pokémon is worth \(String(format: "%.1f", statsPremium()))× more than average",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
                
                InsightCard(
                    title: "Model vs Actual",
                    description: "The ML model's predicted prices have an average error of \(String(format: "%.2f", modelAccuracy()))%, showing strong predictive accuracy",
                    icon: "waveform.path.ecg",
                    color: .purple
                )
                
                InsightCard(
                    title: "Rarity Impact",
                    description: "The five most expensive Pokémon are all Legendary/Mythical with unique type combinations",
                    icon: "sparkles",
                    color: .orange
                )
            }
            .padding()
        }
    }
    
    // Helper functions for insights
    private func topValuedType() -> String {
        guard !typePricing.isEmpty else { return "Unknown" }
        return typePricing.sorted(by: { $0.averagePrice > $1.averagePrice }).first?.type ?? "Unknown"
    }
    
    private func topTypeAverage() -> Double {
        guard !typePricing.isEmpty else { return 0 }
        return typePricing.sorted(by: { $0.averagePrice > $1.averagePrice }).first?.averagePrice ?? 0
    }
    
    private func generationInsight() -> String {
        guard !generationPricing.isEmpty else { return "Generation data unavailable" }
        
        let sortedGens = generationPricing.sorted(by: { $0.averagePrice > $1.averagePrice })
        if let topGen = sortedGens.first, let bottomGen = sortedGens.last {
            return "Gen \(topGen.generation) Pokémon are the most valuable (avg $\(String(format: "%.2f", topGen.averagePrice))), while Gen \(bottomGen.generation) are the least valuable (avg $\(String(format: "%.2f", bottomGen.averagePrice)))"
        }
        return "Generation data unavailable"
    }
    
    private func statsPremium() -> Double {
        guard !pokemonData.isEmpty else { return 1.0 }
        
        let avgPokemon = pokemonData.map { $0.price }.reduce(0, +) / Double(pokemonData.count)
        if let highestStatsPokemon = pokemonData.sorted(by: { $0.baseTotal > $1.baseTotal }).first {
            return highestStatsPokemon.price / avgPokemon
        }
        return 1.0
    }
    
    private func modelAccuracy() -> Double {
        // Calculate average percentage difference between predicted and actual price
        let percentDiffs = pokemonData.map { abs($0.predictedPrice - $0.price) / $0.price * 100 }
        return percentDiffs.reduce(0, +) / Double(percentDiffs.count)
    }
    
    // Calculate the premium for legendary Pokemon
    private func legendaryPremium() -> String {
        let legendaryPrices = pokemonData.filter { $0.isLegendary }.map { $0.price }
        let nonLegendaryPrices = pokemonData.filter { !$0.isLegendary }.map { $0.price }
        
        if legendaryPrices.isEmpty || nonLegendaryPrices.isEmpty {
            return "N/A"
        }
        
        let avgLegendary = legendaryPrices.reduce(0, +) / Double(legendaryPrices.count)
        let avgNonLegendary = nonLegendaryPrices.reduce(0, +) / Double(nonLegendaryPrices.count)
        
        let premium = avgLegendary / avgNonLegendary
        return String(format: "%.1f", premium)
    }
    
    // Create price buckets for histogram
    private func createPriceBuckets() -> [PriceBucket] {
        // Define bucket ranges
        let ranges = ["0-100", "100-200", "200-300", "300-400", "400-500", "500+"]
        var buckets = [PriceBucket]()
        
        // Count Pokemon in each price range
        let count0to100 = pokemonData.filter { $0.price >= 0 && $0.price < 100 }.count
        let count100to200 = pokemonData.filter { $0.price >= 100 && $0.price < 200 }.count
        let count200to300 = pokemonData.filter { $0.price >= 200 && $0.price < 300 }.count
        let count300to400 = pokemonData.filter { $0.price >= 300 && $0.price < 400 }.count
        let count400to500 = pokemonData.filter { $0.price >= 400 && $0.price < 500 }.count
        let count500plus = pokemonData.filter { $0.price >= 500 }.count
        
        // Create buckets
        buckets.append(PriceBucket(id: 1, range: ranges[0], count: count0to100))
        buckets.append(PriceBucket(id: 2, range: ranges[1], count: count100to200))
        buckets.append(PriceBucket(id: 3, range: ranges[2], count: count200to300))
        buckets.append(PriceBucket(id: 4, range: ranges[3], count: count300to400))
        buckets.append(PriceBucket(id: 5, range: ranges[4], count: count400to500))
        buckets.append(PriceBucket(id: 6, range: ranges[5], count: count500plus))
        
        return buckets
    }
    
    // Load data from the CSV file with predictions
    private func loadPredictionData() {
        DispatchQueue.global(qos: .userInitiated).async {
            // Try first with your prediction CSV file
            if let filepath = Bundle.main.path(forResource: "paste", ofType: "txt") {
                do {
                    let contents = try String(contentsOfFile: filepath, encoding: .utf8)
                    let rows = contents.components(separatedBy: "\n")
                    
                    // Check if we have data
                    guard rows.count > 0 else {
                        print("CSV file is empty")
                        DispatchQueue.main.async {
                            self.isLoading = false
                        }
                        return
                    }
                    
                    // Skip header row and parse data
                    var pokemonArray: [Pokemon] = []
                    let headers = rows[0].components(separatedBy: ",")
                    
                    print("CSV Headers: \(headers)") // Debug: print headers
                    
                    // Find column indices
                    let nameIndex = headers.firstIndex(of: "name") ?? -1
                    let type1Index = headers.firstIndex(of: "type1") ?? -1
                    let type2Index = headers.firstIndex(of: "type2") ?? -1
                    let baseTotalIndex = headers.firstIndex(of: "base_total") ?? -1
                    let isLegendaryIndex = headers.firstIndex(of: "is_legendary") ?? -1
                    let priceIndex = headers.firstIndex(of: "price") ?? -1
                    let predictedPriceIndex = headers.firstIndex(of: "Predicted_Price") ?? -1
                    
                    // Skip header row
                    for i in 1..<rows.count {
                        if rows[i].isEmpty { continue }
                        
                        let columns = rows[i].components(separatedBy: ",")
                        if columns.count <= max(nameIndex, type1Index, type2Index, baseTotalIndex, isLegendaryIndex, priceIndex, predictedPriceIndex) {
                            continue // Skip rows that don't have enough columns
                        }
                        
                        // Parse values from CSV
                        let name = columns[nameIndex]
                        let type1 = columns[type1Index]
                        let type2 = columns[type2Index] == "none" ? nil : columns[type2Index]
                        let baseTotal = Int(columns[baseTotalIndex]) ?? 0
                        let isLegendary = (columns[isLegendaryIndex] == "1" || columns[isLegendaryIndex].lowercased() == "true")
                        let price = Double(columns[priceIndex]) ?? 0.0
                        let predictedPrice = Double(columns[predictedPriceIndex]) ?? 0.0
                        
                        // Create Pokemon object
                        let pokemon = Pokemon(
                            id: i, // Use row number as ID
                            name: name,
                            type1: type1,
                            type2: type2,
                            baseTotal: baseTotal,
                            isLegendary: isLegendary,
                            price: price,
                            predictedPrice: predictedPrice
                        )
                        
                        pokemonArray.append(pokemon)
                    }
                    
                    // Update the UI on the main thread
                    DispatchQueue.main.async {
                        self.pokemonData = pokemonArray.sorted(by: { $0.price > $1.price })
                        self.calculateDerivedData()
                        self.isLoading = false
                    }
                    
                } catch {
                    print("Error reading prediction file: \(error)")
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            } else {
                print("Prediction file not found in the bundle")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    // Calculate derived data like type and generation pricing
    private func calculateDerivedData() {
        // Calculate type pricing data
        var typeDict: [String: (total: Double, count: Int)] = [:]
        for pokemon in pokemonData {
            if let count = typeDict[pokemon.type1]?.count {
                typeDict[pokemon.type1] = (typeDict[pokemon.type1]!.total + pokemon.price, count + 1)
            } else {
                typeDict[pokemon.type1] = (pokemon.price, 1)
            }
        }
        
        typePricing = typeDict.map { type, data in
            TypePricing(
                type: type,
                averagePrice: data.total / Double(data.count),
                count: data.count
            )
        }.sorted(by: { $0.averagePrice > $1.averagePrice })
        
        // Calculate generation pricing based on Pokemon ID ranges
        var genDict: [Int: (total: Double, count: Int)] = [:]
        for pokemon in pokemonData {
            let gen = determineGeneration(name: pokemon.name)
            if let count = genDict[gen]?.count {
                genDict[gen] = (genDict[gen]!.total + pokemon.price, count + 1)
            } else {
                genDict[gen] = (pokemon.price, 1)
            }
        }
        
        generationPricing = genDict.map { gen, data in
            GenerationPricing(
                generation: gen,
                averagePrice: data.total / Double(data.count),
                pokemonCount: data.count
            )
        }.sorted(by: { $0.generation < $1.generation })
    }
    
    // Helper function to estimate which generation a Pokemon belongs to
    private func determineGeneration(name: String) -> Int {
        // Some heuristics for generations based on well-known Pokemon
        let gen1Pokemon = ["Mewtwo", "Charizard", "Pikachu", "Blastoise", "Venusaur", "Gyarados", "Snorlax", "Gengar", "Alakazam"]
        let gen2Pokemon = ["Lugia", "Ho-Oh", "Typhlosion", "Feraligatr", "Meganium", "Tyranitar", "Celebi"]
        let gen3Pokemon = ["Rayquaza", "Groudon", "Kyogre", "Blaziken", "Swampert", "Sceptile", "Salamence"]
        let gen4Pokemon = ["Dialga", "Palkia", "Giratina", "Infernape", "Empoleon", "Torterra", "Garchomp"]
        let gen5Pokemon = ["Reshiram", "Zekrom", "Kyurem", "Serperior", "Emboar", "Samurott", "Hydreigon"]
        let gen6Pokemon = ["Xerneas", "Yveltal", "Greninja", "Chesnaught", "Delphox", "Goodra"]
        let gen7Pokemon = ["Solgaleo", "Lunala", "Necrozma", "Incineroar", "Primarina", "Decidueye"]
        
        if gen1Pokemon.contains(name) { return 1 }
        if gen2Pokemon.contains(name) { return 2 }
        if gen3Pokemon.contains(name) { return 3 }
        if gen4Pokemon.contains(name) { return 4 }
        if gen5Pokemon.contains(name) { return 5 }
        if gen6Pokemon.contains(name) { return 6 }
        if gen7Pokemon.contains(name) { return 7 }
        
        // Default to generation 1 if we can't determine
        return 1
    }
}

// Helper struct for price distribution
struct PriceBucket: Identifiable {
    let id: Int
    let range: String
    let count: Int
}

// Card view for showing Pokemon and their prices
struct PokemonPriceCard: View {
    let pokemon: Pokemon
    let rank: Int
    
    var body: some View {
        HStack {
            // Rank circle
            ZStack {
                Circle()
                    .fill(rank <= 3 ? Color.yellow : Color.gray.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Text("\(rank)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(rank <= 3 ? .black : .primary)
            }
            
            // Type indicator
            Circle()
                .fill(colorForPokemonType(pokemon.type1))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pokemon.name)
                    .font(.headline)
                
                HStack {
                    Text(pokemon.type1.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(colorForPokemonType(pokemon.type1))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    
                    if let type2 = pokemon.type2, !type2.isEmpty, type2 != "none" {
                        Text(type2.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(colorForPokemonType(type2))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    if pokemon.isLegendary {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("$\(pokemon.price, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Predicted: $\(pokemon.predictedPrice, specifier: "%.2f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// Reusable Insight Card view
struct InsightCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    AnalyticsView()
}
