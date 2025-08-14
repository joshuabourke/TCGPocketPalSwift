//
//  CardDetailedViewModel.swift
//  TCGPocketPal
//
//  Created by Josh Bourke on 29/5/2025.
//

import SwiftUI

@MainActor
final class CardDetailedViewModel: ObservableObject {
    @Published var cardId: String
    @Published var detailedCard: TCGCard? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let fetchCardForUseCase: FetchCardUseCase
    
    init(cardId: String, fetchCardForUseCase: FetchCardUseCase) {
        self.cardId = cardId
        self.fetchCardForUseCase = fetchCardForUseCase
    }
    
    @MainActor
    func loadCardDetails() async {
        isLoading = true
        errorMessage = nil
        do {
            try await self.detailedCard = fetchCardForUseCase.execute(cardId: cardId)
        } catch{
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
