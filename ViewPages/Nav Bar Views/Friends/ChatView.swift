//
//  ChatView.swift
//  PokeVault
//

import SwiftUI

struct ChatView: View {
    let friend: Friend

    var body: some View {
        VStack {
            Text("Chat with \(friend.name)")
                .font(.largeTitle)
                .padding()
        }
        .navigationTitle("\(friend.name)'s Chat") // Sets proper title
        .navigationBarTitleDisplayMode(.inline)  // Keeps title compact
    }
}
