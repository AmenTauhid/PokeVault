//
//  CollectionView.swift
//  PokeVault
//

import SwiftUI

struct CollectionView: View {
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.red, .black]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Text("Your Collection")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                    
                    ScrollView {
                        ForEach(1..<6) { index in
                            CardView(cardName: "Pokémon Card \(index)")
                        }
                    }
                }
            }
        }
    }
}
