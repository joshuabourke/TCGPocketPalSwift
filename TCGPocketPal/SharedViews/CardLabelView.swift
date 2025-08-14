//
//  CardLabelView.swift
//  TCGPocketPal
//
//  Created by Josh Bourke on 25/7/2025.
//

import SwiftUI

struct CardLabelView: View {
    
    let card: TCGCardSummary
    
    var body: some View {
        VStack {
            ImageLoadingView(baseURL: card.image, imageType: .card(quality: .high, format: .jpg))
            Text(card.name)
                .font(.subheadline)
                .bold()
                .foregroundStyle(.primary)
                .padding(.leading, 8)
        }
        .tcgppContentBackground()
    }
}

#Preview {
    CardLabelView(card: TCGCardSummary(id: "", image: "", localId: "", name: ""))
}
