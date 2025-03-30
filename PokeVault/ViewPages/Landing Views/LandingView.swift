//
//  LandingView.swift
//  PokeVault
//

import SwiftUI

struct LandingView: View {
    @State private var isLoggedIn = false
    
    var body: some View {
        if isLoggedIn {
            ContentView()
        } else {
            ZStack {
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Image("pokeball")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .padding()
                    
                    Text("PokéVault")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                        .padding()
                    
                    Button("Log In") {
                        isLoggedIn = true
                    }
                    .padding()
                    .frame(width: 200)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    
                    Button("Sign Up") {
                        isLoggedIn = true
                    }
                    .padding()
                    .frame(width: 200)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                }
            }
        }
    }
}
