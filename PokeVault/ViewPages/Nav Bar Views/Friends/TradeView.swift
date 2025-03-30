//
//  TradeView.swift
//  PokeVault
//

import SwiftUI

struct TradeView: View {
    let friend: Friend

    var body: some View {
        VStack {
            Text("Trade with \(friend.name)")
                .font(.largeTitle)
                .padding()
        }
        .navigationTitle("\(friend.name)'s Trade") // Sets proper title
        .navigationBarTitleDisplayMode(.inline)  // Keeps title compact
    }
}
