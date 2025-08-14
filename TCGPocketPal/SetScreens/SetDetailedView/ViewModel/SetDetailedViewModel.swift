//
//  SetDetailedViewModel.swift
//  TCGPocketPal
//
//  Created by Josh Bourke on 28/5/2025.
//

import Foundation


@MainActor
final class SetDetailViewModel: ObservableObject {
    @Published var cards: [TCGCardSummary] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var allCards: [TCGCardSummary] = []
    private var currentPage: Int = 1
    private let itemsPerPage: Int = 50

    private let fetchCardsForSetUseCase: FetchCardsForSetUseCase
    
    init(fetchCardsForSetUseCase: FetchCardsForSetUseCase) {
        self.fetchCardsForSetUseCase = fetchCardsForSetUseCase
    }
    
    @MainActor
    func loadCards(setId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            cards = try await fetchCardsForSetUseCase.execute(setId: setId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
//    func fetchCards(for setID: String, reset: Bool = true) {
//        if reset {
//            currentPage = 1
//            cards.removeAll()
//            allCards.removeAll()
//        }
//
//        isLoading = reset
//        errorMessage = nil
//
//        TCGDexManager.shared.fetchCardsForSet(setID: setID) { [weak self] result in
//            guard let self = self else { return }
//            self.isLoading = false
//
//            switch result {
//            case .success(let fullList):
//                self.allCards = fullList
//                let endIndex = min(self.itemsPerPage, self.allCards.count)
//                self.cards = Array(self.allCards.prefix(endIndex))
//            case .failure(let error):
//                self.errorMessage = error.localizedDescription
//            }
//        }
//    }
//
//    func loadMoreIfNeeded(currentCard card: TCGCardSummary, setID: String) {
//        guard let lastCard = cards.last, lastCard.id == card.id else { return }
//
//        let nextPage = currentPage + 1
//        let startIndex = (nextPage - 1) * itemsPerPage
//        let endIndex = min(startIndex + itemsPerPage, allCards.count)
//
//        guard startIndex < allCards.count else { return }
//
//        let nextCards = Array(allCards[startIndex..<endIndex])
//        cards.append(contentsOf: nextCards)
//        currentPage = nextPage
//    }
}
