//
//  LoginPage.swift
//  PokeVault
//
//  Created by Omar Al dulaimi on 2025-03-28.
//

import SwiftUI

struct LoginPage: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    
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
                    
                    Text("PokeVault")
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
                    
                    SecureField("Enter your password", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Forgot password
                HStack {
                    Spacer()
                    Button(action: {
                        showForgotPassword = true
                    }) {
                        Text("Forgot Password?")
                            .foregroundColor(.blue)
                    }
                }
                
                // Error message
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // Login button
                Button(action: {
                    authViewModel.signIn(email: email, password: password)
                }) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Login")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(authViewModel.isLoading)
                
                // Sign up navigation
                HStack {
                    Text("Don't have an account?")
                    Button(action: {
                        showSignUp = true
                    }) {
                        Text("Sign Up")
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showSignUp) {
                SignUp()
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView(authViewModel: authViewModel)
            }
            .fullScreenCover(isPresented: $authViewModel.isAuthenticated) {
                ContentView()
            }
        }
    }
}

struct ForgotPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var showConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Reset Password")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Enter your email address and we'll send you a link to reset your password.")
                    .multilineTextAlignment(.center)
                    .padding(.bottom)
                
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: {
                    authViewModel.resetPassword(email: email)
                    showConfirmation = true
                }) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Send Reset Link")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(authViewModel.isLoading || email.isEmpty)
                
                Spacer()
            }
            .padding()
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
            })
            .alert(isPresented: $showConfirmation) {
                Alert(
                    title: Text("Password Reset"),
                    message: Text("If an account exists with email \(email), a password reset link has been sent."),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
}

#Preview {
    LoginPage()
}
