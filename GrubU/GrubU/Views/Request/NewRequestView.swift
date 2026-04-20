//
//  NewRequestView.swift
//
//  Pick a campus restaurant and pile stuff in your bag.
//
//  Created by Julie Baguio on 4/7/26.
//
import SwiftUI

private enum RestaurantBrowseMetrics {
    /// Hero photo height; image is `scaledToFill` so any aspect ratio / resolution works.
    static let heroHeight: CGFloat = 124
    static let heroCorner: CGFloat = 14
    static let cardCorner: CGFloat = 14
    static let cardSpacing: CGFloat = 12
}

struct NewRequestView: View {
    @ObservedObject var menuManager: MenuManager

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: RestaurantBrowseMetrics.cardSpacing) {
                    ForEach(menuManager.restaurants) { restaurant in
                        RestaurantBrowseCard(restaurant: restaurant, menuManager: menuManager)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, ProfileLayout.horizontalPadding)
                .padding(.bottom, 16 + AppTheme.tabBarBottomClearance)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scrollContentBackground(.hidden)

            if !menuManager.bag.isEmpty {
                bagCheckoutFloatingBar
                    .transition(.move(edge: .bottom))
            }
        }
        .frame(maxWidth: .infinity)
        .background(AppTheme.pageBackground)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { menuManager.fetchMenus() }
    }

    /// Compact Grubhub-style strip: two-line “Your order from …” (left) + single-row pill (count, CTA, meal points).
    private var bagCheckoutFloatingBar: some View {
        let itemCount = menuManager.bag.count
        let pointsLine = EarnAmountFormatting.mealPointsDisplay(menuManager.totalCost)

        return HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Your order from")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(menuManager.bagRestaurantDisplayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.88)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(minWidth: 0, maxWidth: 148, alignment: .leading)

            NavigationLink(destination: FinalCheckoutView(menuManager: menuManager)) {
                HStack(spacing: 8) {
                    Text("\(itemCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.black.opacity(0.28)))

                    Text("View bag & post")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Spacer(minLength: 4)

                    Text(pointsLine)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity)
                .background(AppTheme.accent)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("View bag and post request, \(itemCount) items, \(pointsLine) meal points")
        }
        .padding(.horizontal, ProfileLayout.horizontalPadding)
        .padding(.vertical, 6)
        .padding(.bottom, AppTheme.tabBarBottomClearance)
        .background(AppTheme.pageBackground)
        .overlay(alignment: .top) {
            Divider()
                .background(Color(.separator).opacity(0.45))
        }
        .shadow(color: .black.opacity(0.06), radius: 8, y: -3)
    }
}

// MARK: - Grubhub-style restaurant tile

private struct RestaurantBrowseCard: View {
    let restaurant: Restaurant
    @ObservedObject var menuManager: MenuManager

    var body: some View {
        NavigationLink(destination: RestaurantDetailView(restaurant: restaurant, menuManager: menuManager)) {
            VStack(alignment: .leading, spacing: 8) {
                RestaurantHeroImage(urlString: restaurant.imageUrl)

                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(restaurant.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Text(restaurant.location)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .padding(.trailing, 2)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 2)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: RestaurantBrowseMetrics.cardCorner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: RestaurantBrowseMetrics.cardCorner, style: .continuous)
                    .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

private struct RestaurantHeroImage: View {
    let urlString: String?

    var body: some View {
        CachedRemoteImageView(
            urlString: urlString,
            height: RestaurantBrowseMetrics.heroHeight,
            cornerRadius: RestaurantBrowseMetrics.heroCorner
        )
    }
}
