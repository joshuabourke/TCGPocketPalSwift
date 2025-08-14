//
//  MainScreen.swift
//  TCGPocketPal
//
//  Created by Josh Bourke on 28/5/2025.
//

import SwiftUI

struct MainScreen: View {
    @StateObject var viewModel: MainScreenViewModel
    let container: DIContainer
    
    init(viewModel: MainScreenViewModel, container: DIContainer) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.container = container
    }
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack {
                    if viewModel.isLoadingSets {
                        ProgressView("Loading...")
                            .bold()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    } else {
                        if let error = viewModel.fetchError {
                            Text("Error: \(error)")
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        } else {
                            LazyVGrid(columns: columns) {
                                ForEach(viewModel.tcgpSets, id: \.id) { set in
                                    NavigationLink(destination: SetDetailView(viewModel: container.makeSetDetailViewModel(), set: set, container: container)) {
                                        SetListRowView(set: set)
                                    }//: LINK
                                    .buttonStyle(.plain)// <- removes the automatic blue tint of the button.
                                }//: SET LOOP
                            }//: LAZY V GRID
                            .padding([.horizontal, .bottom])
                        }
                    }
                }//: VSTACK
            }//: SCROLL VIEW
            .tcgppBackground()
            .onFirstAppear(perform: {
                Task(priority: .high) {
                    await viewModel.loadTCGPSets()
                }
            })
            .navigationTitle("TCGPocketPal")
        }
    }

}


#Preview {
    let repo = TCGDexRepository()
    let useCase = FetchSeriesUseCase(repository: repo)
    MainScreen(viewModel: MainScreenViewModel(fetchSeriesUseCase: useCase), container: DIContainer())
}


    



