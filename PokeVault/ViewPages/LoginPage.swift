#Preview {
    LoginPage()
}//
//  LoginPage.swift
//  PokeVault
//
//  Created by Omar Al dulaimi on 2025-03-28.
//

import SwiftUI
import FirebaseFirestore

// MARK: - Pokémon Type Theme Colors
struct PokemonTypeTheme: Equatable {
    let primary: Color
    let secondary: Color
    let gradient: LinearGradient
    
    static func == (lhs: PokemonTypeTheme, rhs: PokemonTypeTheme) -> Bool {
        // Compare the colors to determine equality
        return lhs.primary == rhs.primary && lhs.secondary == rhs.secondary
    }
    
    static let fire = PokemonTypeTheme(
        primary: Color(hex: "FF5733"),
        secondary: Color(hex: "FFC300"),
        gradient: LinearGradient(
            gradient: Gradient(colors: [Color(hex: "FF5733"), Color(hex: "FFC300")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    
    static let water = PokemonTypeTheme(
        primary: Color(hex: "6890F0"),
        secondary: Color(hex: "98D8D8"),
        gradient: LinearGradient(
            gradient: Gradient(colors: [Color(hex: "6890F0"), Color(hex: "98D8D8")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    
    static let electric = PokemonTypeTheme(
        primary: Color(hex: "F8D030"),
        secondary: Color(hex: "FAE078"),
        gradient: LinearGradient(
            gradient: Gradient(colors: [Color(hex: "F8D030"), Color(hex: "FAE078")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    
    static let grass = PokemonTypeTheme(
        primary: Color(hex: "78C850"),
        secondary: Color(hex: "A7DB8D"),
        gradient: LinearGradient(
            gradient: Gradient(colors: [Color(hex: "78C850"), Color(hex: "A7DB8D")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    
    static let psychic = PokemonTypeTheme(
        primary: Color(hex: "F85888"),
        secondary: Color(hex: "FA92B2"),
        gradient: LinearGradient(
            gradient: Gradient(colors: [Color(hex: "F85888"), Color(hex: "FA92B2")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Floating Particles View
struct FloatingParticlesView: View {
    let theme: PokemonTypeTheme
    
    var body: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { index in
                Circle()
                    .fill(index % 2 == 0 ? theme.primary : theme.secondary)
                    .frame(width: CGFloat.random(in: 10...40), height: CGFloat.random(in: 10...40))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .opacity(0.2)
                    .animation(
                        Animation.linear(duration: Double.random(in: 8...15))
                            .repeatForever()
                            .delay(Double.random(in: 0...5)),
                        value: index
                    )
            }
        }
    }
}

// MARK: - Pokeball View
struct PokeballView: View {
    let animating: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 100, height: 100)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            // Top half (red)
            Rectangle()
                .fill(Color.red)
                .frame(width: 100, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 50))
                .offset(y: -25)
            
            // Middle line
            Rectangle()
                .fill(Color.black)
                .frame(width: 100, height: 4)
            
            // Center button
            Circle()
                .fill(Color.white)
                .frame(width: 30, height: 30)
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 3)
                )
                .background(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                )
        }
        .rotationEffect(Angle(degrees: animating ? 360 : 0))
        .animation(animating ? Animation.linear(duration: 1.0).repeatForever(autoreverses: false) : nil, value: animating)
    }
}

// MARK: - Custom TextField Style
struct PokemonTextFieldStyle: ViewModifier {
    let theme: PokemonTypeTheme
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .shadow(color: theme.primary.opacity(0.2), radius: 5, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(theme.primary.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Login Page
struct LoginPage: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    @State private var isSettingUpUser = false
    @State private var isAnimating = false
    @State private var activeTheme = PokemonTypeTheme.fire
    @State private var themeIndex = 0
    
    let themes: [PokemonTypeTheme] = [.fire, .water, .electric, .grass]
    
    // Timer to cycle themes
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated background gradient
                activeTheme.gradient
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 1.5), value: activeTheme)
                
                // Floating particles
                FloatingParticlesView(theme: activeTheme)
                    .opacity(0.4)
                
                // Main content
                ScrollView {
                    VStack(spacing: 20) {
                        // Logo and app name
                        VStack {
                            PokeballView(animating: isAnimating)
                                .frame(width: 100, height: 100)
                                .padding(.bottom, 5)
                            
                            Text("PokéVault")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 30)
                        
                        // Login Card
                        VStack(spacing: 20) {
                            // Email field
                            VStack(alignment: .leading) {
                                Text("Email")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .padding(.leading, 5)
                                
                                TextField("Enter your email", text: $email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .modifier(PokemonTextFieldStyle(theme: activeTheme))
                            }
                            
                            // Password field
                            VStack(alignment: .leading) {
                                Text("Password")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .padding(.leading, 5)
                                
                                SecureField("Enter your password", text: $password)
                                    .modifier(PokemonTextFieldStyle(theme: activeTheme))
                            }
                            
                            // Forgot password
                            HStack {
                                Spacer()
                                Button(action: {
                                    showForgotPassword = true
                                }) {
                                    Text("Forgot Password?")
                                        .foregroundColor(activeTheme.primary)
                                        .font(.subheadline)
                                }
                            }
                            .padding(.top, -5)
                            
                            // Error message
                            if let errorMessage = authViewModel.errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .padding(.vertical, 5)
                            }
                            
                            // Login button
                            Button(action: {
                                withAnimation {
                                    isAnimating = true
                                }
                                
                                // Simulate haptic feedback
                                let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
                                impactHeavy.impactOccurred()
                                
                                authViewModel.signIn(email: email, password: password)
                                isSettingUpUser = true
                                
                                // Turn off animation after a delay if not successful
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    if !authViewModel.isAuthenticated {
                                        isAnimating = false
                                    }
                                }
                            }) {
                                ZStack {
                                    // Button background
                                    Capsule()
                                        .fill(activeTheme.gradient)
                                        .frame(height: 50)
                                        .shadow(color: activeTheme.primary.opacity(0.4), radius: 5, x: 0, y: 3)
                                    
                                    // Button content
                                    if authViewModel.isLoading || isSettingUpUser {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(1.2)
                                    } else {
                                        Text("Login")
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .font(.title3)
                                    }
                                }
                            }
                            .disabled(authViewModel.isLoading || isSettingUpUser)
                            .padding(.top, 5)
                            
                            // Sign up navigation
                            HStack {
                                Text("Don't have an account?")
                                    .foregroundColor(.gray)
                                Button(action: {
                                    showSignUp = true
                                }) {
                                    Text("Sign Up")
                                        .fontWeight(.semibold)
                                        .foregroundColor(activeTheme.primary)
                                }
                            }
                            .padding(.top, 10)
                        }
                        .padding(25)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal)
                        
                        // Type selector
                        HStack(spacing: 15) {
                            ForEach(0..<themes.count, id: \.self) { index in
                                Circle()
                                    .fill(themes[index].primary)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: themeIndex == index ? 3 : 0)
                                    )
                                    .scaleEffect(themeIndex == index ? 1.2 : 1.0)
                                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                                    .onTapGesture {
                                        withAnimation {
                                            themeIndex = index
                                            activeTheme = themes[index]
                                        }
                                    }
                            }
                        }
                        .padding(.top, 25)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .onReceive(timer) { _ in
                // Auto cycle themes if not manually changed recently
                withAnimation {
                    themeIndex = (themeIndex + 1) % themes.count
                    activeTheme = themes[themeIndex]
                }
            }
            .fullScreenCover(isPresented: $showSignUp) {
                SignUp(authViewModel: authViewModel, theme: activeTheme)
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView(authViewModel: authViewModel, theme: PokemonTypeTheme.psychic)
            }
            .fullScreenCover(isPresented: $authViewModel.isAuthenticated) {
                ContentView()
            }
        }
    }
}

// MARK: - Sign Up View
struct SignUp: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var isSettingUpUser = false
    @State private var selectedStarter = 0
    let theme: PokemonTypeTheme
    
    let starters = [
        ("Bulbasaur", PokemonTypeTheme.grass),
        ("Charmander", PokemonTypeTheme.fire),
        ("Squirtle", PokemonTypeTheme.water)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                starters[selectedStarter].1.gradient
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.8), value: selectedStarter)
                
                // Floating particles
                FloatingParticlesView(theme: starters[selectedStarter].1)
                    .opacity(0.4)
                
                ScrollView {
                    VStack(spacing: 25) {
                        Text("Choose Your Starter")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.2), radius: 2)
                            .padding(.top, 20)
                        
                        // Starter selection
                        HStack(spacing: 20) {
                            ForEach(0..<starters.count, id: \.self) { index in
                                Button(action: {
                                    withAnimation {
                                        selectedStarter = index
                                    }
                                    // Haptic feedback
                                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                                    impactMed.impactOccurred()
                                }) {
                                    VStack {
                                        Circle()
                                            .fill(starters[index].1.primary)
                                            .frame(width: 70, height: 70)
                                            .overlay(
                                                Text(String(starters[index].0.prefix(1)))
                                                    .font(.system(size: 24, weight: .bold))
                                                    .foregroundColor(.white)
                                            )
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: selectedStarter == index ? 4 : 0)
                                            )
                                            .shadow(color: Color.black.opacity(0.3), radius: 5)
                                        
                                        Text(starters[index].0)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    }
                                    .scaleEffect(selectedStarter == index ? 1.1 : 0.9)
                                    .opacity(selectedStarter == index ? 1.0 : 0.7)
                                }
                            }
                        }
                        .padding(.bottom, 10)
                        
                        // Sign up form
                        VStack(spacing: 18) {
                            Text("Create Trainer Account")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(starters[selectedStarter].1.primary)
                            
                            // Name field
                            VStack(alignment: .leading) {
                                Text("Trainer Name")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .padding(.leading, 5)
                                
                                TextField("Enter your name", text: $name)
                                    .modifier(PokemonTextFieldStyle(theme: starters[selectedStarter].1))
                            }
                            
                            // Email field
                            VStack(alignment: .leading) {
                                Text("Email")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .padding(.leading, 5)
                                
                                TextField("Enter your email", text: $email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .modifier(PokemonTextFieldStyle(theme: starters[selectedStarter].1))
                            }
                            
                            // Password field
                            VStack(alignment: .leading) {
                                Text("Password")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .padding(.leading, 5)
                                
                                SecureField("Create a password", text: $password)
                                    .modifier(PokemonTextFieldStyle(theme: starters[selectedStarter].1))
                            }
                            
                            // Confirm Password field
                            VStack(alignment: .leading) {
                                Text("Confirm Password")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .padding(.leading, 5)
                                
                                SecureField("Confirm your password", text: $confirmPassword)
                                    .modifier(PokemonTextFieldStyle(theme: starters[selectedStarter].1))
                            }
                            
                            // Error message
                            if let errorMessage = authViewModel.errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .padding(.vertical, 5)
                            }
                            
                            // Sign up button
                            Button(action: {
                                if password != confirmPassword {
                                    authViewModel.errorMessage = "Passwords do not match"
                                    return
                                }
                                
                                // Haptic feedback
                                let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
                                impactHeavy.impactOccurred()
                                
                                isSettingUpUser = true
                                authViewModel.signUp(email: email, password: password, name: name) { success in
                                    if success {
                                        // Instead of calling signIn directly, set a flag in the view model
                                        // that will trigger the ContentView when the SignUp sheet is dismissed
                                        authViewModel.isAuthenticated = true
                                    }
                                    isSettingUpUser = false
                                }
                            }) {
                                ZStack {
                                    // Button background
                                    Capsule()
                                        .fill(starters[selectedStarter].1.gradient)
                                        .frame(height: 50)
                                        .shadow(color: starters[selectedStarter].1.primary.opacity(0.4), radius: 5, x: 0, y: 3)
                                    
                                    // Button content
                                    if authViewModel.isLoading || isSettingUpUser {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(1.2)
                                    } else {
                                        Text("Sign Up")
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .font(.title3)
                                    }
                                }
                            }
                            .disabled(authViewModel.isLoading || isSettingUpUser)
                            .padding(.top, 5)
                        }
                        .padding(25)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal)
                        
                        Spacer(minLength: 30)
                    }
                    .padding()
                }
            }
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                    Text("Back")
                }
                .foregroundColor(.white)
                .padding(8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.3))
                )
            })
            .navigationBarBackButtonHidden(true)
        }
    }
}

// MARK: - Forgot Password View
struct ForgotPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var showConfirmation = false
    @State private var isAnimating = false
    let theme: PokemonTypeTheme
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                theme.gradient
                    .ignoresSafeArea()
                
                // Floating particles - musical notes for Jigglypuff theme
                ZStack {
                    ForEach(0..<15, id: \.self) { index in
                        Text(["♪", "♫", "♩", "♬", "♭"][index % 5])
                            .font(.system(size: CGFloat.random(in: 20...40)))
                            .foregroundColor(.white)
                            .opacity(0.2)
                            .position(
                                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                                y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                            )
                            .animation(
                                Animation.linear(duration: Double.random(in: 8...15))
                                    .repeatForever()
                                    .delay(Double.random(in: 0...5)),
                                value: index
                            )
                    }
                }
                
                VStack(spacing: 25) {
                    // Header
                    Text("Forgot Password?")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 2)
                    
                    Text("Don't worry, we'll help you!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    // Jigglypuff character - simple circular representation
                    ZStack {
                        Circle()
                            .fill(Color.pink.opacity(0.8))
                            .frame(width: 120, height: 120)
                            .shadow(color: Color.black.opacity(0.2), radius: 10)
                        
                        // Eyes
                        HStack(spacing: 30) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 20, height: 20)
                            
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 20, height: 20)
                        }
                        .offset(y: -10)
                        
                        // Mouth
                        Capsule()
                            .fill(Color.red.opacity(0.7))
                            .frame(width: 25, height: 10)
                            .offset(y: 20)
                        
                        // Ears if animating
                        if isAnimating {
                            Circle()
                                .fill(Color.pink.opacity(0.6))
                                .frame(width: 40, height: 40)
                                .offset(x: -45, y: -45)
                            
                            Circle()
                                .fill(Color.pink.opacity(0.6))
                                .frame(width: 40, height: 40)
                                .offset(x: 45, y: -45)
                        }
                    }
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
                    .animation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isAnimating)
                    .onAppear {
                        isAnimating = true
                    }
                    
                    // Form card
                    VStack(spacing: 20) {
                        Text("Enter your email address and we'll send you a link to reset your password.")
                            .multilineTextAlignment(.center)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.bottom, 5)
                        
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .modifier(PokemonTextFieldStyle(theme: theme))
                        
                        if let errorMessage = authViewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        Button(action: {
                            // Haptic feedback
                            let impactMed = UIImpactFeedbackGenerator(style: .medium)
                            impactMed.impactOccurred()
                            
                            authViewModel.resetPassword(email: email)
                            showConfirmation = true
                        }) {
                            ZStack {
                                // Button background
                                Capsule()
                                    .fill(theme.gradient)
                                    .frame(height: 50)
                                    .shadow(color: theme.primary.opacity(0.4), radius: 5, x: 0, y: 3)
                                
                                // Button content
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.2)
                                } else {
                                    Text("Send Reset Link")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .font(.title3)
                                }
                            }
                        }
                        .disabled(authViewModel.isLoading || email.isEmpty)
                    }
                    .padding(25)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                    Text("Back")
                }
                .foregroundColor(.white)
                .padding(8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.3))
                )
            })
            .navigationBarBackButtonHidden(true)
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

// MARK: - Preview
// MARK: - Auth View Model Extension
extension AuthViewModel {
    // This method directly sets the authentication state to bypass the need for a second sign-in
    func completeSignUpAndAuthenticate() {
        self.isAuthenticated = true
    }
}
