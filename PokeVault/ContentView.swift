//
//  ContentView.swift
//  PokeVault
//
//  Created by Ayman Tauhid on 2025-03-28.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                // Main app content
                HomeView(authViewModel: authViewModel)
            } else {
                // Authentication flow
                LoginPage()
            }
        }
    }
}

// Placeholder for the main home view after authentication
struct HomeView: View {
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome to PokeVault!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Image(systemName: "pokeball")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.red)
                    .padding()
                
                Text("You are logged in as:")
                    .padding(.top)
                
                if let email = authViewModel.user?.email {
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
                
                Spacer()
            }
            .padding()
            .navigationTitle("PokeVault")
        }
    }
}

#Preview {
    ContentView()
}
