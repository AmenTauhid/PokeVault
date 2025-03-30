//
//  AccountView.swift
//  PokeVault
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct AccountView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var cardCount: Int = 0
    @State private var isLoading: Bool = true
    @State private var userName: String = ""
    @State private var userEmail: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading profile...")
                } else {
                    // Profile header
                    VStack(spacing: 20) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.blue)
                            .padding(.top, 30)
                        
                        Text(userName.isEmpty ? "Pokémon Trainer" : userName)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(userEmail)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 30)
                    
                    // Stats section
                    VStack(spacing: 20) {
                        HStack {
                            Text("Collection Stats")
                                .font(.headline)
                                .padding(.leading)
                            Spacer()
                        }
                        
                        HStack(spacing: 20) {
                            StatCard(title: "Total Cards", value: "\(cardCount)", icon: "star.fill", color: .orange)
                            
                            // Add more stat cards as needed
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Sign out button
                    Button(action: signOut) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .frame(minWidth: 200)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Account")
            .onAppear {
                loadUserData()
                fetchCardCount()
            }
        }
    }
    
    private func loadUserData() {
        if let user = Auth.auth().currentUser {
            userEmail = user.email ?? "No email"
            userName = user.displayName ?? "Pokémon Trainer"
            
            // Fetch user data from Firestore
            let db = Firestore.firestore()
            db.collection("users").document(user.uid).getDocument { document, error in
                if let document = document, document.exists {
                    if let data = document.data() {
                        userName = data["name"] as? String ?? userName
                    }
                }
            }
        }
    }
    
    private func fetchCardCount() {
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        
        // Navigate to the correct nested collection path
        // users -> userId -> pokemon_cards
        db.collection("users").document(userId).collection("pokemon_cards")
            .getDocuments { snapshot, error in
                isLoading = false
                
                if let error = error {
                    print("Error fetching cards: \(error.localizedDescription)")
                    return
                }
                
                if let snapshot = snapshot {
                    cardCount = snapshot.documents.count
                    print("Found \(cardCount) cards for user \(userId)")
                }
            }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            authViewModel.isAuthenticated = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .padding(.bottom, 5)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView(authViewModel: AuthViewModel())
    }
}

