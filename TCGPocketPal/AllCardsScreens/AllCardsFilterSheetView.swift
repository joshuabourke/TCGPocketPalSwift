//
//  AllCardsFilterSheetView.swift
//  TCGPocketPal
//
//  Created by Josh Bourke on 4/8/2025.
//

import SwiftUI

struct AllCardsFilterSheetView: View {
    @ObservedObject var viewModel: AllCardsScreenViewModel
    @Binding var isPresented: Bool
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "circle.fill")
                        .bold()
                        .foregroundStyle(.gray)
                    Text("Types")
                        .bold()
                        .foregroundStyle(.gray)
                }//: HSTACK
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(CardTypes.allCases, id: \.self) { type in
                        Button {
                            if !viewModel.typeFilterArray.contains(type.rawValue) {
                                viewModel.typeFilterArray.append(type.rawValue.lowercased())
                            } else{
                                viewModel.typeFilterArray.removeAll { removeType in
                                    removeType == type.rawValue.lowercased()
                                }
                            }
                        } label: {
                            HStack {
                                Circle().fill(type.color).frame(width: 20)
                                Text(type.rawValue.capitalized)
                                    .bold()
                                Spacer()
                                if viewModel.isTypeFilterToggled(for: type.rawValue.lowercased()) {
                                   Image(systemName: "checkmark")
                                        .bold()
                                        .foregroundColor(type.color)
                                }
                            }//: HSTACK
                            .padding(.horizontal, 4)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(viewModel.isTypeFilterToggled(for: type.rawValue.lowercased()) ? Color(UIColor.tertiaryLabel) : Color(UIColor.secondarySystemFill), in: .capsule)
                        }
                        .buttonStyle(.plain)
                    }//: LOOP
                }//: LAZY V GRID
                .tcgppContentBackground()
                .padding(.vertical, 4)
                HStack {
                    Image(systemName: "rectangle.stack")
                        .bold()
                        .foregroundStyle(.gray)
                    Text("Sets")
                        .bold()
                        .foregroundStyle(.gray)
                }//: HSTACK
                if viewModel.isSetsLoading {
                    ProgressView("Loading Sets...")
                        .bold()
                } else {
                    if let error = viewModel.setsErrorMessage {
                        VStack(spacing: 4) {
                            Text("Unable to fetch sets at this time...")
                                .bold()
                                
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }//: VSTACK
                        .tcgppContentBackground()
                    } else {
                        LazyVGrid(columns: columns) {
                            ForEach(viewModel.sets, id: \.id) { set in
                                Button {
                                    if !viewModel.setFilterArray.contains(set.id) {
                                        viewModel.setFilterArray.append(set.id)
                                    } else {
                                        viewModel.setFilterArray.removeAll { setId in
                                            setId == set.id
                                        }
                                    }
                                } label: {
                                    SetListRowView(set: set)
                                        .overlay(alignment: .topLeading) {
                                            if viewModel.isSetFilterToggled(for: set.id) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.green)
                                                    .bold()
                                                    .padding(6)
                                                    .background(.ultraThickMaterial, in: .rect(cornerRadius: 8))
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }//: LOOP
                        }//: LAZY V GRID
                    }
                }
            }//: VSTACK
            .padding()
        }//: SCROLL
        .tcgppBackground()
        .onFirstAppear(perform: {
            Task(priority: .background) {
                await viewModel.fetchSets()
            }
        })
        .overlay {
            VStack {
                Spacer()
                HStack {
                    Button {
                        Task {
                            await viewModel.makeFilter()
                        }
                        isPresented = false
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.gray)
                                .bold()
                            Text("Search")
                                .foregroundStyle(.gray)
                                .bold()
                        }//: HSTACK
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(Color(uiColor: UIColor.tertiarySystemBackground), in: .capsule)
                    }
                    Spacer()
                    Button {
                        withAnimation {
                            viewModel.clearFilter()
                            isPresented = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.gray)
                                .bold()
                            Text("Clear")
                                .foregroundStyle(.gray)
                                .bold()
                        }//: HSTACK
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(Color(uiColor: UIColor.tertiarySystemBackground), in: .capsule)
                    }
                }//: HSTACK
                .padding()
                .tcgppBackground()
            }//: VSTACK
        }//: OVERLAY
    }
    

}

#Preview {
    let repo = TCGDexRepository()
    let useCase = FetchAllCardsUseCase(repository: repo)
    AllCardsFilterSheetView(viewModel: AllCardsScreenViewModel(fetchAllCardsUseCase: useCase),isPresented: .constant(false))
}
