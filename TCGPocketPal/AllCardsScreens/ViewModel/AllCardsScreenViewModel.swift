//
//  AllCardsScreenViewModel.swift
//  TCGPocketPal
//
//  Created by Josh Bourke on 25/7/2025.
//

import Foundation

final class AllCardsScreenViewModel: ObservableObject {
    
    @Published var allCards: [TCGCardSummary] = []
    @Published var filteredCards: [TCGCard] = []
    @Published var sets: [TCGPSet] = []
    
    //When fetching the list of 'TCGCardSummary'
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    //-------------------------//

    @Published var isLoadingForFilter: Bool = false
    
    //When fetching sets....
    @Published var isSetsLoading: Bool = false
    @Published var setsErrorMessage: String?
    //-------------------------//
    
    //For creating the filter...
    @Published var typeFilterArray: [String] = []
    @Published var setFilterArray: [String] = []
    @Published var filterURL: String = ""
    //-------------------------//
    
    //Text filtered cards locally... using the 'TCGCardSummary'
    @Published var searchText: String = ""
    
    var filterdCards: [TCGCardSummary] {
        guard !self.searchText.isEmpty else { return allCards}
        
        return allCards.filter { card in
            let cardName = card.name.lowercased()
            return cardName.localizedStandardContains(searchText.lowercased())
        }
    }
    //-------------------------//
    
    
    private let fetchAllCardsUseCase: FetchAllCardsUseCase
    
    init(fetchAllCardsUseCase: FetchAllCardsUseCase) {
        self.fetchAllCardsUseCase = fetchAllCardsUseCase
    }
    
    @MainActor
    func loadAllCards() async {
        isLoading = true
        errorMessage = nil
        
        do {
            allCards = try await fetchAllCardsUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    func fetchCardsForFilter() async {
        isLoadingForFilter = true
        errorMessage = nil
        
        do {
            let url = filterURL
            allCards = try await fetchAllCardsUseCase.executeFilter(with: url)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingForFilter = false
    }
    
    @MainActor
    func fetchSets() async {
        isSetsLoading = true
        setsErrorMessage = nil
        do {
            sets = try await fetchAllCardsUseCase.executeSetFetch().sets
        } catch {
            setsErrorMessage = error.localizedDescription
        }
        isSetsLoading = false
    }
    
    //MARK: - FILTER SHEET VIEW
    /// The purpose of this function is to append each of the API filters for fetching cards based on the selected filters.
    @MainActor
    func makeFilter() async {
        //Important as I am only looking to get TCGPocket cards. The set filter needs to be set for all the current TCGPocket sets. So if the set filter is empty we are passing in all sets. If they have actually selected a set to filter on we are only passing in that set.
        
        if !typeFilterArray.isEmpty && !setFilterArray.isEmpty {
            filterURL = "types=like:\(typeFilterArray.joined(separator: "|"))&set=\(setFilterArray.joined(separator: "|"))"
        } else if !typeFilterArray.isEmpty && setFilterArray.isEmpty {
            filterURL = "types=like:\(typeFilterArray.joined(separator: "|"))&set=\(sets.map{$0.id}.joined(separator: "|"))"
        } else if typeFilterArray.isEmpty && !setFilterArray.isEmpty {
            filterURL = "set=like:\(setFilterArray.joined(separator: "|"))"
        }

        print("FilterURL: \(filterURL)")
        
        await fetchCardsForFilter()
        
    }
    
    /// The purpose of this function is to check if the filter is applied. It is going to do that by checking if the filter string contains the button filter. Returning a bool to show the filter toggled on or off
    func isTypeFilterToggled(for button: String) -> Bool {
        typeFilterArray.contains(button)
    }
    
    func isSetFilterToggled(for button: String) -> Bool {
        setFilterArray.contains(button)
    }
    
    func clearFilter() {
        filterURL = ""
        setFilterArray.removeAll()
        typeFilterArray.removeAll()
        Task {
           await loadAllCards()
        }
    }
}
