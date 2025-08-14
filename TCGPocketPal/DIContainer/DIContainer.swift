//
//  DIContainer.swift
//  TCGPocketPal
//
//  Created by Josh Bourke on 24/7/2025.
//

import Foundation

@MainActor
final class DIContainer: ObservableObject {
    
    lazy var tcgRepository: TCGCardRepository = TCGDexRepository()
    
    lazy var fetchCardUseCase = FetchCardUseCase(repository: tcgRepository)
    
    lazy var fetchCardsForSetUseCase = FetchCardsForSetUseCase(repository: tcgRepository)
    
    lazy var fetchSeriesUseCase = FetchSeriesUseCase(repository: tcgRepository)
    
    lazy var fetchAllCardsUseCase = FetchAllCardsUseCase(repository: tcgRepository)
    
    lazy var imagesManager = ImagesManager()
    
    //MARK: - VIEW MODEL FACTORY
    func makeMainScreenVieModel() -> MainScreenViewModel {
        return MainScreenViewModel(fetchSeriesUseCase: fetchSeriesUseCase)
    }
    
    func makeSetDetailViewModel() -> SetDetailViewModel {
        return SetDetailViewModel(fetchCardsForSetUseCase: fetchCardsForSetUseCase)
    }
    
    func makeCardDetailedViewModel(cardId: String) -> CardDetailedViewModel {
        return CardDetailedViewModel(cardId: cardId, fetchCardForUseCase: fetchCardUseCase)
    }
    
    func makeAllCardsScreenViewModel() -> AllCardsScreenViewModel {
        return AllCardsScreenViewModel(fetchAllCardsUseCase: fetchAllCardsUseCase)
    }
    
    // Primary method for TCG images with type specification
    func makeImageLoadingViewModel(
        baseURL: String,
        imageType: TCGImageType,
        variant: ImageVariant = .full
    ) -> ImageLoadingViewModel {
        return ImageLoadingViewModel(
            baseURL: baseURL,
            imageType: imageType,
            variant: variant,
            imageManager: imagesManager
        )
    }
    
    // For direct URLs
    func makeDirectImageLoadingViewModel(
        imageURL: String,
        variant: ImageVariant = .full
    ) -> ImageLoadingViewModel {
        return ImageLoadingViewModel(
            directURL: imageURL,
            variant: variant,
            imageManager: imagesManager
        )
    }
}
