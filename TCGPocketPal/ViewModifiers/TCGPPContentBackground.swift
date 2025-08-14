//
//  TCGPPContentBackground.swift
//  TCGPocketPal
//
//  Created by Josh Bourke on 4/6/2025.
//

import Foundation
import SwiftUI

struct TCGPPContentBackground<Background: ShapeStyle>: ViewModifier {
    
    let padding: CGFloat
    let cornerRadius: CGFloat
    let width: CGFloat?
    let height: CGFloat?
    let background: Background
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: width, maxHeight: height)
            .background(background)
            .cornerRadius(cornerRadius)
    }
}

extension View {
    /// When using content background color in views that do not scroll. Width and Height should = nil.
    func tcgppContentBackground<Background: ShapeStyle>(padding: CGFloat = 8, cornerRadius: CGFloat = 12, width: CGFloat? = .infinity, height: CGFloat? = .infinity, background: Background = Color(uiColor: UIColor.tertiarySystemBackground)) -> some View {
        modifier(TCGPPContentBackground(padding: padding, cornerRadius: cornerRadius, width: width, height: height, background: background))
    }
}
