//
//  AuthViewModel.swift
//  PokeVault
//
//  Created by Omar Al dulaimi on 2025-03-28.
//

import Foundation
import FirebaseAuth
import Combine

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Check if user is already logged in
        self.user = Auth.auth().currentUser
        self.isAuthenticated = user != nil
        
        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isAuthenticated = user != nil
        }
    }
    
    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            self?.isLoading = false
            
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }
            
            // Successfully signed in
            self?.isAuthenticated = true
        }
    }
    
    func signUp(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            self?.isLoading = false
            
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }
            
            // Successfully created user
            self?.isAuthenticated = true
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
        } catch let error {
            errorMessage = error.localizedDescription
        }
    }
    
    func resetPassword(email: String) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            self?.isLoading = false
            
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }
            
            // Successfully sent reset email
        }
    }
}
