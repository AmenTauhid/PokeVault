//
//  ContentView.swift
//  PokeVault
//

import SwiftUI

struct ContentView: View {
    var body: some View {
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
        }
        .accentColor(.red)
    }
}
