//
//  CardView.swift
//  PokeVault
//

import SwiftUI

struct CardView: View {
    var cardName: String
    
    var body: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .padding()
            
            Text(cardName)
                .font(.title2)
                .foregroundColor(.white)
                .bold()
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.3)))
        .padding(.horizontal)
    }
}
