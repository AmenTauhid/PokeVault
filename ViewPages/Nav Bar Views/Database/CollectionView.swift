//
//  CollectionView.swift
//  PokeVault
//

import SwiftUI
import FirebaseAuth

struct CollectionView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
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
                    Text("You are logged in as:")
                        .padding(.top)
                    
                    if let email = Auth.auth().currentUser?.email {
                        Text(email)
                            .font(.headline)
                    }
                    
                    Button(action: {
                        authViewModel.signOut()
                    }) {
                        Text("Sign Out")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.top, 30)
                    .padding(.horizontal)
                }
            }
        }
    }
}
