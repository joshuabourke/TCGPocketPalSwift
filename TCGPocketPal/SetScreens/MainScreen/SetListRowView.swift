//
//  SetListRowView.swift
//  TCGPocketPal
//
//  Created by Josh Bourke on 4/8/2025.
//

import SwiftUI

struct SetListRowView: View {
    let set: TCGPSet
    var body: some View {
        setListRowView(for: set)
    }
    
    @ViewBuilder
    func setListRowView(for set: TCGPSet) -> some View {
        VStack {
            ImageLoadingView(baseURL: set.logo, imageType: .logo(format: .png))
        }//: VSTACK
        .tcgppContentBackground()
        .overlay(alignment: .topTrailing, content: {
            VStack {
                Text(set.id)
                    .font(.caption)
                    .foregroundStyle(.foreground)
                    .bold()
                    .padding(6)
                    .background(.ultraThickMaterial, in: .rect(cornerRadius: 8))
                Spacer()
            }//: VSTACK
            .padding([.trailing, .top], 8)
        })
    }
}

#Preview {
    SetListRowView(set: TCGPSet(cardCount: CardCount(official: 0, total: 0), id: "A1", logo: nil, name: nil, symbol: nil, releaseDate: nil, serie: nil, legal: nil, boosters: nil, cards: nil))
}
