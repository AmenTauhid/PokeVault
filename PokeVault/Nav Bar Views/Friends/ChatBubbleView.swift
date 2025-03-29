//
//  ChatBubbleView.swift
//  PokeVault
//

import SwiftUI

struct ChatBubbleView: View {
    var message: String
    
    var body: some View {
        HStack {
            Text(message)
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(10)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}
