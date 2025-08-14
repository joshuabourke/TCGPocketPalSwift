//
//  AllCardsScreen.swift
//  TCGPocketPal
//
//  Created by Josh Bourke on 25/7/2025.
//

import SwiftUI

struct AllCardsScreen: View {
    @StateObject var viewModel: AllCardsScreenViewModel
    let container: DIContainer
    
    init(viewModel: AllCardsScreenViewModel, container: DIContainer) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.container = container
    }
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    @FocusState var searchFocus: Bool
    
    @State private var showFilterView: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if let errorMessage = viewModel.errorMessage {
                    LazyVStack {
                        Text("\(errorMessage)")
                            .foregroundStyle(.red)
                    }//: VSTACK
                } else {
                    VStack {
                        searchBar
                        if !viewModel.setFilterArray.isEmpty || !viewModel.typeFilterArray.isEmpty {
                            filterView
                        }
                        LazyVGrid(columns: columns) {
                            ForEach(viewModel.filterdCards, id: \.id) { card in
                                NavigationLink {
                                    CardDetailedView(card: card, viewModel: container.makeCardDetailedViewModel(cardId: card.id))
                                } label: {
                                    CardLabelView(card: card)
                                }
                            }//: LOOP
                        }//: LAZY V GRID
                    }//:VSTACK
                    .padding()
                }
            }//: SCROLL
            .tcgppBackground()
            .navigationTitle("All Cards")
            .sheet(isPresented: $showFilterView) {
                AllCardsFilterSheetView(viewModel: viewModel, isPresented: $showFilterView)
                    .presentationDetents([.medium, .large])
            }
            .overlay(alignment:.center) {
                if viewModel.isLoadingForFilter {
                    VStack {
                        ProgressView()
                        Text("Fetching cards...")
                            .bold()
                            .foregroundStyle(.secondary)
                    }//: VSTACK
                    .padding(8)
                    .frame(width: 300, height: 300)
                    .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
                }
            }
        }//: NAV
        .onFirstAppear(perform: {
            Task(priority: .high) {
                if viewModel.allCards.isEmpty {
                    await viewModel.loadAllCards()
                }
            }
        })
    }
    
    //MARK: - SUB VIEW
    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .bold()
                
                TextField("Search cards...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .focused($searchFocus)
                
                //Need to only show this when the text field is active. This is going exit the user out of typing.
                if searchFocus {
                    Button {
                        searchFocus = false
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .bold()
                    }
                }
            }//: HSTACK
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.tertiarySystemBackground))
            )
            Button {
                showFilterView.toggle()
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.secondary)
                    .bold()
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.tertiarySystemBackground))
                    )
            }
        }//: HSTACK
        .padding(.bottom, 10)
    }
    
    private var filterView: some View {
        HStack {
            HStack {
                Image(systemName: "slider.horizontal.3")
                Text("Filters: \(viewModel.setFilterArray.count + viewModel.typeFilterArray.count)")
            }//: HSTACK
            .foregroundColor(.secondary)
            .bold()
            .font(.caption)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(viewModel.setFilterArray + viewModel.typeFilterArray, id: \.self) { filter in
                        HStack {
                            if viewModel.typeFilterArray.contains(filter) {
                                Circle().fill(CardTypes(rawValue: filter)?.color ?? .gray.opacity(0.3)).frame(width: 10)
                            }
                            Text(filter.capitalized)
                                .bold()
                                .font(.caption)
                        }//: HSTACK
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(.ultraThinMaterial, in: .capsule)
                    }//: LOOP
                }//: HSTACK
            }//: SCROLL
            if !viewModel.setFilterArray.isEmpty || !viewModel.typeFilterArray.isEmpty {
                Button {
                    withAnimation {
                        viewModel.clearFilter()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                        .bold()
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
            }
        }//: HSTACK

    }

}

#Preview {
    let repo = TCGDexRepository()
    let useCase = FetchAllCardsUseCase(repository: repo)
    AllCardsScreen(viewModel: AllCardsScreenViewModel(fetchAllCardsUseCase: useCase), container: DIContainer())
}
