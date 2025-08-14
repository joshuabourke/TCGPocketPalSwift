//
//  CardDetailedView.swift
//  TCGPocketPal
//
//  Created by Josh Bourke on 29/5/2025.
//

import SwiftUI

struct CardDetailedView: View {
    let card: TCGCardSummary
    @StateObject var viewModel: CardDetailedViewModel
    
    init(card: TCGCardSummary, viewModel: CardDetailedViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.card = card
    }
    
    var body: some View {
        ScrollView {
                VStack {
                    ImageLoadingView(baseURL: card.image, imageType: .card(quality: .high, format: .jpg))
                    if viewModel.isLoading {
                        ProgressView("Loading card...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    } else {
                        HStack {
                            Image(systemName: "lanyardcard.fill")
                                .bold()
                                .foregroundStyle(.gray)
                            Text("Card Details")
                                .bold()
                                .foregroundStyle(.gray)
                        }//: HSTACK
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                        VStack {
                            cardHeaderSection()
                            if let detailedCard = viewModel.detailedCard {
                                cardDetails(for: detailedCard)
                            } else {
                                Text(viewModel.errorMessage ?? "Unable to load card details at this time...")
                                    .foregroundStyle(.red)
                            }
                        }//: VSTACK
                        .tcgppContentBackground()
                    }
                }//: VSTACK
                .padding()
        }
        .tcgppBackground()
        .navigationTitle(card.name)
        .task(priority: .high) {
            await viewModel.loadCardDetails()
        }
    }
    
    //MARK: - SUB VIEWS
    /// The card header section is going to use information that has already been loaded. Whilst the detailed view is fetching extra information.
    private func cardHeaderSection() -> some View {
        HStack {
            if let stage = viewModel.detailedCard?.stage {
                Text(stage)
                    .bold()
                    .font(.caption2)
            }
            Text(card.name)
                .font(.title3)
                .bold()
            if let detailedCard = viewModel.detailedCard {
                Spacer()
                if let hp = detailedCard.hp {
                    Text("HP").font(.caption).bold() +
                    Text(" \(hp)").font(.title3).bold()
                }
                if let types = detailedCard.types {
                    ForEach(Array(types.enumerated()), id:\.offset) { index, type in
                        if let typeColor = CardTypes(rawValue: type.lowercased()) {
                            Circle().fill(typeColor.color).frame(width: 30)
                        }
                    }
                }
            }
        }//: HSTACK
    }
    
    /// The purpose of this view is to consume the 'TCGCard' and display the information.
    private func cardDetails(for card: TCGCard) -> some View {
        VStack {
            if let abilities = card.abilities {
                VStack {
                    ForEach(Array(abilities.enumerated()), id: \.offset) { index, ability in
                        HStack {
                            Text(ability.type)
                                .bold()
                                .font(.caption)
                                .padding(4)
                                .background(Color.red.opacity(0.3), in: .rect(cornerRadius: 8))
                            Text(ability.name)
                                .bold()
                            Spacer()
                        }//: HSTACK
                        Text(ability.effect)
                            .font(.caption).bold()
                            .foregroundStyle(.gray)
                    }//: LOOP
                }//: VSTACK
                .padding(.bottom, 8)
            }
            if let attacks = card.attacks {
                VStack {
                    ForEach(attacks, id: \.name) { attack in
                        HStack {
                            VStack {
                                HStack {
                                    ForEach(Array(attack.cost.enumerated()), id: \.offset) { index, energyType in
                                        if let color = CardTypes(rawValue: energyType.lowercased()) {
                                            Circle().fill(color.color).frame(width: 20)
                                        }
                                    }//: LOOP
                                    Text(attack.name)
                                        .bold()
                                    Spacer()
                                    if let damage = attack.damage {
                                        Text(damage.value)
                                            .bold()
                                            .padding(.trailing, 8)
                                    }
                                }//: HSTACK
                                .padding(.bottom, 4)
                                if let effect = attack.effect {
                                    Text(effect)
                                        .bold()
                                        .font(.caption)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }//: VSTACK
                            Spacer()
                        }//: HSTACK
                        .padding(.bottom, 4)
                    }//: LOOP
                }//: VSTACK
                .padding(8)
            }//: Attacks
            if let effect = card.effect {
                Text(effect)
                    .font(.caption)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }//: VSTACK
    }
}

/// This is going to take the pokemon type string and then return what is needed.
enum CardTypes: String, CaseIterable {
    case grass = "grass"
    case colorless = "colorless"
    case fire = "fire"
    case water = "water"
    case lightning = "lightning"
    case psychic = "psychic"
    case metal = "metal"
    case darkness = "darkness"
    case fighting = "fighting"
    case dragon = "dragon"
    
    var color: Color {
        switch self {
        case .grass:
            Color.green.opacity(0.5)
        case .colorless:
            Color.white.opacity(0.5)
        case .fire:
            Color.red.opacity(0.5)
        case .water:
            Color.blue.opacity(0.5)
        case .lightning:
            Color.yellow.opacity(0.5)
        case .psychic:
            Color.purple.opacity(0.5)
        case .metal:
            Color.gray.opacity(0.5)
        case .darkness:
            Color.black.opacity(0.5)
        case .fighting:
            Color.brown.opacity(0.5)
        case .dragon:
            Color.orange.opacity(0.5)
        }
    }
}

//#Preview {
//    CardDetailedView(card: TCGCard(id: <#T##String#>, image: <#T##String#>, localId: <#T##String#>, name: <#T##String#>))
//}
