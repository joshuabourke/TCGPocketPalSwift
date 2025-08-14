//
//  ContentView.swift
//  TCGPocketPal
//
//  Created by Josh Bourke on 28/5/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var container: DIContainer
    
    var body: some View {
        TabView {
            MainScreen(viewModel: container.makeMainScreenVieModel(), container: container)
                .tabItem {
                    Image(systemName: "rectangle.stack")
                    Text("Sets")
                }
            AllCardsScreen(viewModel: container.makeAllCardsScreenViewModel(), container: container)
                .tabItem {
                    Image(systemName: "rectangle.grid.2x2")
                    Text("All Cards")
                }
        }

    }
}

#Preview {
    ContentView()
}
