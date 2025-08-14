//
//  TCGDexManager.swift
//  TCGPocketPal
//
//  Created by Josh Bourke on 28/5/2025.
//

import Foundation
import SwiftUI
// MARK: - Series Models

struct TCGPSeries: Codable {
    let id: String
    let logo: String?
    let name: String
    let firstSet: TCGPSet?
    let lastSet: TCGPSet?
    let releaseDate: String?
    let sets: [TCGPSet]
}

/// The current available sets of cards.
struct TCGPSet: Codable {
    let cardCount: CardCount
    let id: String
    let logo: String?
    let name: String?
    let symbol: String?
    
    let releaseDate: String?
    let serie: Serie?
    let legal: Legal?
    let boosters: [Booster]?
    let cards: [TCGCardSummary]?
}

struct Serie: Codable {
    let id: String
    let name: String
}

struct TCGCardSummary: Codable, Identifiable {
    let id: String
    let image: String?
    let localId: String
    let name: String
}

struct TCGCard: Codable, Identifiable {
    let id: String
    let category: String
    let illustrator: String
    let image: String
    let localId: String
    let name: String
    let rarity: String
    let set: SetInfo
    let variants: Variants
    let effect: String? //This is for trainer cards and item cards and possibly for cards that have an effect.
    let hp: Int?
    let types: [String]?
    let description: String?
    let stage: String?
    let abilities: [Abilities]?
    let attacks: [Attack]?
    let weaknesses: [Weakness]?
    let retreat: Int?
    let legal: Legal
    let boosters: [Booster]?
    let updated: String
}

struct SetInfo: Codable {
    let cardCount: CardCount
    let id: String
    let logo: String?
    let name: String
    let symbol: String?
}

struct CardCount: Codable {
    let official: Int
    let total: Int
}

struct Variants: Codable {
    let firstEdition, holo, normal, reverse, wPromo: Bool
}

struct Abilities: Codable {
    let type: String
    let name: String
    let effect: String
}

struct Attack: Codable {
    let cost: [String]
    let name: String
    let effect: String?
    let damage: StringOrInt?
}


struct Weakness: Codable {
    let type: String
    let value: String
}

struct Legal: Codable {
    let standard: Bool
    let expanded: Bool
}

struct Booster: Codable {
    let id: String
    let name: String
}

struct SetResponse: Codable {
    let cards: [TCGCardSummary]
}

enum StringOrInt: Codable {
    case string(String)
    case int(Int)

    var value: String {
        switch self {
        case .string(let str): return str
        case .int(let num): return String(num)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .string(str)
        } else if let num = try? container.decode(Int.self) {
            self = .int(num)
        } else {
            throw DecodingError.typeMismatch(
                StringOrInt.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected String or Int for StringOrInt enum"
                )
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let str): try container.encode(str)
        case .int(let num): try container.encode(num)
        }
    }
}

// MARK: - TCGDex Manager



/// URL for TCGPocket Series aka all the sets: "https://api.tcgdex.net/v2/en/series/tcgp"
/// URL for singular Set: "https://api.tcgdex.net/v2/en/sets/{setId}"
/// URL for singular card: "https://api.tcgdex.net/v2/en/cards/{cardId}"
/// URL for singular card Image: "https://assets.tcgdex.net/en/tcgp/A1/003/high.png"
/// boo_A1-mewtwo
/// URL for filtering cards from a set example: "https://api.tcgdex.net/v2/en/cards?set=A1a"
/// URL for filtering cards by type example: https://api.tcgdex.net/v2/en/cards?types=like:grass&set=A2a
/// 'types=like:grass, is a way the api will check if types contains 'grass'. &set=A2a is also checking the set the card is from.
/// Applying multiple set fitlers would look something like this set=A1|A1a|A1b|A2|A2a|A2b

//MARK: - DOMAIN LAYER
protocol TCGCardRepository {
    func fetchCard(with id: String) async throws -> TCGCard
    func fetchTCGSeries() async throws -> TCGPSeries
    func fetchNewTCGSeries() async throws -> TCGPSeries
    func fetchCardsForSet(setId: String) async throws -> [TCGCardSummary]
    func fetchAllCards() async throws -> [TCGCardSummary]
    func fetchCardsForFilter(with url: String) async throws -> [TCGCardSummary]
}

///This is going to fetch a single card.
class FetchCardUseCase {
    private let repository: TCGCardRepository
    
    init(repository: TCGCardRepository) {
        self.repository = repository
    }
    
    func execute(cardId: String) async throws -> TCGCard {
        return try await repository.fetchCard(with: cardId)
    }
}

///This is going to fetch the cards for the set.
class FetchCardsForSetUseCase {
    private let repository: TCGCardRepository
    
    init(repository: TCGCardRepository) {
        self.repository = repository
    }
    
    func execute(setId: String) async throws -> [TCGCardSummary] {
        return try await repository.fetchCardsForSet(setId: setId)
    }
}

class FetchSeriesUseCase {
    private let repository: TCGCardRepository
    
    init(repository: TCGCardRepository) {
        self.repository = repository
    }
    
    func execute() async throws -> TCGPSeries {
        return try await repository.fetchTCGSeries()
    }
    
    func executeNewFetch() async throws -> TCGPSeries {
        return try await repository.fetchNewTCGSeries()
    }
}


class FetchAllCardsUseCase {
    private let repository: TCGCardRepository
    
    init(repository: TCGCardRepository) {
        self.repository = repository
    }
    /// Fetch all the cards
    func execute() async throws -> [TCGCardSummary] {
        return try await repository.fetchAllCards()
    }
    /// Fetch the sets, this is used for filtering. Fetching the sets again to make sure we have all available sets and possible new sets.
    func executeSetFetch() async throws -> TCGPSeries {
        return try await repository.fetchTCGSeries()
    }
    
    /// Filter cards. This will fetch for cards using the API's filter. For example  only fire pokemon or only pokemon from a certain set and fire type.
    func executeFilter(with url: String) async throws -> [TCGCardSummary] {
        return try await repository.fetchCardsForFilter(with: url)
    }

}

class TCGDexRepository: TCGCardRepository {
    
    
    let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService()) {
        self.networkService = networkService
    }
    
    /// Fetch a single card with its card Id.
    func fetchCard(with id: String) async throws -> TCGCard {
        let url = "https://api.tcgdex.net/v2/en/cards/\(id)"
        return try await networkService.fetch(TCGCard.self, from: url)
    }
    
    /// This is going to fetch all the cards for the Trading Card Game Pocket Series. Use TCGPSeries.sets to get an array of the sets. This fetch will use the cache is available.
    func fetchTCGSeries() async throws -> TCGPSeries {
        let url = "https://api.tcgdex.net/v2/en/series/tcgp"
        return try await networkService.fetch(TCGPSeries.self, from: url)
    }
    
    /// This is going to fetch all the cards for the Trading Card Game Pocket Series. Use TCGPSeries.sets to get an array of the sets. This will fetch ignoring the cache both local and remote.
    func fetchNewTCGSeries() async throws -> TCGPSeries {
        let url = "https://api.tcgdex.net/v2/en/series/tcgp"
        return try await networkService.fetchRegarlessOfCache(TCGPSeries.self, from: url)
    }
    
    /// Fetch all the card that come with this set. Used in the set detailed view.
    func fetchCardsForSet(setId: String) async throws -> [TCGCardSummary] {
        let url = "https://api.tcgdex.net/v2/en/sets/\(setId)"
        let response = try await networkService.fetch(SetResponse.self, from: url)
        return response.cards
    }
    

    /// For fetching cards in the api with a filter.
    func fetchCardsForFilter(with url: String) async throws -> [TCGCardSummary] {
        ///EXAMPLE URL:  https://api.tcgdex.net/v2/en/cards?types=like:grass|fire&set=A1|A1a|A1b|A2|A2a|A2b
        let url = "https://api.tcgdex.net/v2/en/cards?\(url)"
        return try await networkService.fetch([TCGCardSummary].self, from: url)
    }
    
    /// For fetching every single card. From each and every set available.
    func fetchAllCards() async throws -> [TCGCardSummary] {
        let allSeries = try await fetchTCGSeries()
        let setIds = allSeries.sets.map { $0.id }
        
        print("### Fetching cards from \(setIds.count) sets: \(setIds)")
        
        // Use TaskGroup for concurrent fetching
        let allCards = try await withThrowingTaskGroup(of: [TCGCardSummary].self) { group in
            // Add tasks for each set
            for setId in setIds {
                group.addTask {
                    let url = "https://api.tcgdex.net/v2/en/sets/\(setId)"
                    print("🔄 Fetching set: \(setId)")
                    let response = try await self.networkService.fetch(SetResponse.self, from: url)
                    print("✅ Completed set: \(setId) - \(response.cards.count) cards")
                    return response.cards
                }
            }
            
            // Collect all results
            var cards: [TCGCardSummary] = []
            for try await setCards in group {
                cards.append(contentsOf: setCards)
            }
            return cards
        }
        
        print("📊 Total cards fetched: \(allCards.count)")
        return allCards
    }
    
}

class NetworkService {
    
    /// Normal fetch method, non async.
    func fetch<T: Codable>(_ type: T.Type, from url: String, completion: @escaping (Result<T, Error>) -> Void) {
            
        guard let url = URL(string: "\(url)") else {
            completion(.failure(URLError(.badURL)))
            return }
        
        print("Valid url...")
            URLSession.shared.dataTask(with: url) { data, response, error in
                DispatchQueue.main.async {
                    ///Check for errors
                    if let error {
                        completion(.failure(error))
                        return
                    }
                    ///Check if data isn't nil
                    guard let data = data else {
                        completion(.failure(URLError(.badServerResponse)))
                        return
                    }
                    
                    do {
                        let deocdedData = try JSONDecoder().decode(type, from: data)
                        completion(.success(deocdedData))
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
            .resume()
        }
    
    ///Async fetching method.
    func fetch<T: Codable>(_ type: T.Type, from url: String) async throws -> T {
        
        guard let url = URL(string: url) else {
            throw URLError(.badURL)
        }
        
        print("Fetching URL \(url)...")
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        print("Raw data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
        
    
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Decoding Error: \(error)")
            throw error
        }
    }
    
    ///This fetch method is going to fetch ignoring the local and remote cache data.
    func fetchRegarlessOfCache<T: Codable>(_ type: T.Type, from url: String) async throws -> T {
        
        guard let url = URL(string: url) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        print("Fetching URL \(url)...")
        
        let (data, _) = try await  URLSession.shared.data(for: request)
        
        print("Raw data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Decoding Error: \(error)")
            throw error
        }
    }
}
