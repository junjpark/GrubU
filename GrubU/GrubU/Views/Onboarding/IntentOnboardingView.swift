//
//  IntentOnboardingView.swift
//
//  First launch cards: here to earn, get help, or both.
//
//  Created by Julie Baguio on 4/7/26.
//

import SwiftUI

struct IntentOnboardingView: View {
    let uid: String
    var onCommitted: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("What brings you here today?")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)

                Text("Pick one — you can always switch tabs later.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 16) {
                    intentCard(
                        title: "Earn money helping others",
                        emoji: "💰",
                        intent: .earn
                    )
                    intentCard(
                        title: "Get help with tasks",
                        emoji: "📥",
                        intent: .requestHelp
                    )
                    intentCard(
                        title: "Both — I want to do either",
                        emoji: "🔄",
                        intent: .both
                    )
                }
                .padding(.horizontal)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func intentCard(title: String, emoji: String, intent: PrimaryUserIntent) -> some View {
        Button {
            UserIntentStore.setIntent(intent, for: uid)
            onCommitted()
        } label: {
            HStack(spacing: 16) {
                Text(emoji)
                    .font(.system(size: 36))
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.borderless)
    }
}
