//
//  TCGPocketPalApp.swift
//  TCGPocketPal
//
//  Created by Josh Bourke on 28/5/2025.
//

import SwiftUI

@main
struct TCGPocketPalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(DIContainer())
        }
    }
}
