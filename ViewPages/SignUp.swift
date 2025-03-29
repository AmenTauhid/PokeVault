//
//  SignUp.swift
//  PokeVault
//
//  Created by Omar Al dulaimi on 2025-03-28.
//

import SwiftUI

struct SignUp: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var authViewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var passwordsMatch = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo/Header
                VStack {
                    Image(systemName: "pokeball")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.red)
                    
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.bottom, 30)
                
                // Email field
                VStack(alignment: .leading) {
                    Text("Email")
                        .font(.headline)
                    
                    TextField("Enter your email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Password field
                VStack(alignment: .leading) {
                    Text("Password")
                        .font(.headline)
                    
                    SecureField("Create a password", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Confirm Password field
                VStack(alignment: .leading) {
                    Text("Confirm Password")
                        .font(.headline)
                    
                    SecureField("Confirm your password", text: $confirmPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Error messages
                if !passwordsMatch {
                    Text("Passwords do not match")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // Sign Up button
                Button(action: {
                    if password == confirmPassword {
                        passwordsMatch = true
                        authViewModel.signUp(email: email, password: password)
                    } else {
                        passwordsMatch = false
                    }
                }) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign Up")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                
                // Login navigation
                HStack {
                    Text("Already have an account?")
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Login")
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.primary)
            })
            .fullScreenCover(isPresented: $authViewModel.isAuthenticated) {
                ContentView()
            }
        }
    }
}

#Preview {
    SignUp()
}
