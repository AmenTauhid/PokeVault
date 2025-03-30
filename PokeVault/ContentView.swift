//
//  ContentView.swift
//  PokeVault
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                HomeView(authViewModel: authViewModel)
            } else {
                LoginPage()
            }
        }
    }
}

struct HomeView: View {
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            TabView {
                CollectionView()
                    .tabItem {
                        Label("Database", systemImage: "tray.full.fill")
                    }
                AnalyticsView()
                    .tabItem {
                        Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                    }
                FriendsView()
                    .tabItem {
                        Label("Friends", systemImage: "person.2.fill")
                    }
                AccountView(authViewModel: authViewModel)
                    .tabItem {
                        Label("Account", systemImage: "person.circle.fill")
                    }
            }
            .accentColor(.red)
        }
    }
}

#Preview {
    ContentView()
}
