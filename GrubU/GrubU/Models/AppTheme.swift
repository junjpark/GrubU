//
//  AppTheme.swift
//
//  Shared color tokens for consistent page + surface styling.
//
//  Created by Julie Baguio on 4/20/26.
//

import SwiftUI

enum AppTheme {
    static let accent = Color.orange
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

/// Uppercase orange section chrome matching `ProfileView.sectionTitle`.
struct ProfileSectionHeader: View {
    let title: String
    var systemImage: String?

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .textCase(.uppercase)
                .tracking(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
        .padding(.bottom, 10)
    }
}
