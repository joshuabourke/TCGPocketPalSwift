//
//  TCGPPBackground.swift
//  TCGPocketPal
//
//  Created by Josh Bourke on 31/5/2025.
//

import SwiftUI


import SwiftUI

struct TCGPPBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThickMaterial)
    }
}

extension View {
    /// This applies a background color. Default is .thinMaterial.
    func tcgppBackground() -> some View {
        modifier(TCGPPBackground())
    }
}
