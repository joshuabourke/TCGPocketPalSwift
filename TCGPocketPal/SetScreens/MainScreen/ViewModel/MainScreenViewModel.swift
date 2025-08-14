//
//  MainScreenViewModel.swift
//  TCGPocketPal
//
//  Created by Josh Bourke on 28/5/2025.
//

import Foundation

@MainActor
final class MainScreenViewModel: ObservableObject {
    @Published var tcgpSets: [TCGPSet] = []
    @Published var isLoadingSets: Bool = false
    @Published var fetchError: String?

    private var fetchSeriesUseCase: FetchSeriesUseCase
    
    init(fetchSeriesUseCase: FetchSeriesUseCase) {
        self.fetchSeriesUseCase = fetchSeriesUseCase
    }
    
    @MainActor
    /// This is going to fetch all of the sets to be displayed.
    func loadTCGPSets() async {
        isLoadingSets = true
        fetchError = nil
        
        do {
            tcgpSets = try await fetchSeriesUseCase.executeNewFetch().sets
        } catch {
            fetchError = error.localizedDescription
        }
        isLoadingSets = false
    }
}
