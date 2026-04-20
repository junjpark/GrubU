//
//  HelperBannerView.swift
//
//  Little orange hint bar you can dismiss (UserDefaults remembers).
//
//  Created by Julie Baguio on 4/7/26.
//

import SwiftUI

struct HelperBannerView: View {
    let storageKey: String
    let text: String

    @State private var dismissed: Bool

    init(storageKey: String, text: String) {
        self.storageKey = storageKey
        self.text = text
        let key = "grubu.helperBanner.dismissed.\(storageKey)"
        _dismissed = State(initialValue: UserDefaults.standard.bool(forKey: key))
    }

    private var persistenceKey: String {
        "grubu.helperBanner.dismissed.\(storageKey)"
    }

    var body: some View {
        Group {
            if !dismissed {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.orange)
                    Text(text)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Spacer(minLength: 8)
                    Button {
                        dismissed = true
                        UserDefaults.standard.set(true, forKey: persistenceKey)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Dismiss hint")
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
