//
//  AppTheme.swift
//
//  Shared color tokens for consistent page + surface styling.
//
//  Created by Julie Baguio on 4/20/26.
//

import SwiftUI

enum AppTheme {
    static let accent = Color(red: 1.0, green: 0.36, blue: 0.22)
    static let pageBackground = Color.white
    static let surfaceBackground = Color(red: 0.972, green: 0.965, blue: 0.952)

    /// Extra space for scroll/footers so content stays above the custom tab bar + home indicator.
    static let tabBarBottomClearance: CGFloat = 76
}

extension View {
    /// Beige modal tile + hairline border (same idea as `ProfileView`’s `modalCard`).
    func profileModalCardStyle() -> some View {
        background(AppTheme.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
            )
    }
}
