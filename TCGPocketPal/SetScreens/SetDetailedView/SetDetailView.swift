//
//  SetDetailView.swift
//  TCGPocketPal
//
//  Created by Josh Bourke on 28/5/2025.
//

import SwiftUI

struct SetDetailView: View {
    @StateObject var viewModel: SetDetailViewModel
    let set: TCGPSet
    let container: DIContainer

    
    init(viewModel: SetDetailViewModel, set: TCGPSet, container: DIContainer) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.set = set
        self.container = container
    }
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading Cards...")
                    
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(viewModel.cards, id: \.id) { card in
                            NavigationLink {
                                CardDetailedView(card: card, viewModel: container.makeCardDetailedViewModel(cardId: card.id))
                            } label: {
                                CardLabelView(card: card)
                            }
                        }//: LOOP
                    }//: LAZY V GRID
                    .padding()
                }
            }
        }
        .tcgppBackground()
        .navigationTitle(set.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task(priority: .high, {
            Task {
                await viewModel.loadCards(setId: set.id)
            }
            print("\(set)")
        })
    }
}
//
//#Preview {
//    SetDetailView(set: TCGPSet(cardCount: CardCount(official: 226, total: 286), id: "A1", logo: "https://assets.tcgdex.net/en/tcgp/A1/logo", name: "Genetic Apex", symbol: "https://assets.tcgdex.net/univ/tcgp/A1/symbol"))
//}
