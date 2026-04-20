//
//  RestaurantDetailView.swift
//
//  One restaurant’s menu; plus buttons chuck items in the bag.
//
//  Created by Julie Baguio on 4/7/26.
//
import SwiftUI
import Foundation

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    @ObservedObject var menuManager: MenuManager

    @State private var showRestaurantAlert = false
    @State private var showToast = false
    @State private var addedItemName = ""

    private var accent: Color { AppTheme.accent }
    private var pageBackground: Color { AppTheme.pageBackground }

    private static let detailHeroHeight: CGFloat = 220

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    CachedRemoteImageView(
                        urlString: restaurant.imageUrl,
                        height: Self.detailHeroHeight,
                        cornerRadius: 0
                    )
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 18,
                            bottomTrailingRadius: 18,
                            topTrailingRadius: 0,
                            style: .continuous
                        )
                    )

                    LazyVStack(spacing: 12) {
                        ForEach(restaurant.items) { item in
                            menuItemRow(item: item)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(menuRowCardBackground)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, ProfileLayout.horizontalPadding)
                    .padding(.top, 14)
                    .padding(.bottom, AppTheme.tabBarBottomClearance + 24)
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity)
            .scrollContentBackground(.hidden)
            .background(pageBackground)
            .navigationTitle(restaurant.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(pageBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert(isPresented: $showRestaurantAlert) {
                Alert(
                    title: Text("Different Restaurant"),
                    message: Text("You can only order from one restaurant at a time. Please clear your bag to switch."),
                    dismissButton: .default(Text("OK"))
                )
            }

            if showToast {
                toastBanner
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal, ProfileLayout.horizontalPadding)
                    .padding(.bottom, AppTheme.tabBarBottomClearance + 16)
                    .zIndex(1)
            }
        }
        .background(pageBackground)
        .animation(.spring(), value: showToast)
    }

    private var menuRowCardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(AppTheme.surfaceBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
            )
    }

    @ViewBuilder
    private func menuItemRow(item: MenuItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                Text(item.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text("$\(item.price, specifier: "%.2f")")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(accent)
                    .monospacedDigit()
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            Button {
                let success = menuManager.addToBag(item, from: restaurant.id ?? "")
                if success {
                    triggerToast(for: item.name)
                } else {
                    showRestaurantAlert = true
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(accent)
            }
            .buttonStyle(.plain)
            .fixedSize(horizontal: true, vertical: false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private var toastBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(accent)
            Text("Added \(addedItemName) to bag")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(AppTheme.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }

    private func triggerToast(for name: String) {
        addedItemName = name
        showToast = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showToast = false
            }
        }
    }
}
