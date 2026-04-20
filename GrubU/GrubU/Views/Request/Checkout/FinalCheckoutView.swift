//
//  FinalCheckoutView.swift
//
//  Bag recap + link off to pay / post the order.
//
//  Created by Julie Baguio on 4/7/26.
//
import SwiftUI

struct FinalCheckoutView: View {
    @ObservedObject var menuManager: MenuManager

    var bounty: Double {
        (menuManager.totalCost * 0.50 * 100).rounded() / 100
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ProfileSectionHeader(title: "Items in bag", systemImage: "bag.fill")

                VStack(spacing: 0) {
                    ForEach(Array(menuManager.bagDisplayLines.enumerated()), id: \.1.id) { index, line in
                        HStack(alignment: .center, spacing: 0) {
                            bagItemRow(line: line)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Button(role: .destructive) {
                                menuManager.removeBagDisplayLine(id: line.id)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.tertiary)
                                    .padding(.trailing, 14)
                                    .accessibilityLabel("Remove from bag")
                            }
                            .buttonStyle(.plain)
                        }
                        if index < menuManager.bagDisplayLines.count - 1 {
                            Divider()
                                .background(Color(.separator))
                        }
                    }
                }
                .profileModalCardStyle()

                ProfileSectionHeader(title: "Cost breakdown", systemImage: "chart.bar.fill")

                VStack(spacing: 0) {
                    checkoutSummaryRow(label: "Meal points cost", value: String(format: "$%.2f", menuManager.totalCost))
                    Divider()
                        .background(Color(.separator))
                    checkoutSummaryRow(label: "Bounty (50%)", value: String(format: "$%.2f", bounty))
                }
                .profileModalCardStyle()

                NavigationLink {
                    OrderReviewView(
                        menuManager: menuManager,
                        restaurantName: menuManager.restaurants.first(where: { $0.id == menuManager.currentRestaurantID })?.name ?? "Unknown",
                        items: menuManager.bag,
                        foodCost: menuManager.totalCost,
                        bounty: bounty
                    )
                } label: {
                    HStack {
                        Spacer()
                        Text("Review order")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(AppTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, 20)

                Spacer(minLength: 24)
            }
            .padding(.horizontal, ProfileLayout.horizontalPadding)
            .padding(.top, 18)
            .padding(.bottom, AppTheme.tabBarBottomClearance)
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.pageBackground)
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bagItemRow(line: BagDisplayLine) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(line.quantity > 1 ? "\(line.quantity)× \(line.item.name)" : line.item.name)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 16)
            Text(String(format: "$%.2f", line.lineTotal))
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .monospacedDigit()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }

    private func checkoutSummaryRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 16)
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .monospacedDigit()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }
}
