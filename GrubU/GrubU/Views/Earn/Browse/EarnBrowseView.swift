//
//  EarnBrowseView.swift
//
//  Available-request card layout for the Earn feed (used by EarnTabView).
//
//  Created by Julie Baguio on 4/7/26.
//

import SwiftUI

// MARK: - Shared earn feed formatting

enum EarnAmountFormatting {
    static func mealPointsDisplay(_ foodCost: Double) -> String {
        let v = foodCost
        if abs(v - round(v)) < 0.001 {
            return String(Int(v.rounded()))
        }
        return String(format: "%.2f", v)
    }

    static func payoutHeadline(bounty: Double) -> String {
        String(format: "+$%.2f", bounty)
    }
}

/// MEAL POINTS (leading, black) + PAYOUT (trailing, accent) for available-request cards.
struct EarnPayoutMealPointsHeader: View {
    let bountyAmount: Double
    let foodCost: Double

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("MEAL POINTS")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                Text(EarnAmountFormatting.mealPointsDisplay(foodCost))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                Text("PAYOUT")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                Text(EarnAmountFormatting.payoutHeadline(bounty: bountyAmount))
                    .font(.title.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
            }
        }
    }
}

// MARK: - Available request card

struct EarnAvailableRequestCard: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            EarnPayoutMealPointsHeader(bountyAmount: order.bountyAmount, foodCost: order.foodCost)

            Text(orderContentsSummary)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(5)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(locationLine)
                    .foregroundStyle(.secondary)
                if let posted = relativePosted(order.createdAt) {
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(posted)
                        .foregroundStyle(.tertiary)
                }
            }
            .font(.caption2)
            .lineLimit(2)

            HStack {
                Spacer(minLength: 0)
                HStack(spacing: 5) {
                    Text("Accept Order")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                }
                .accessibilityLabel("Accept order, view details")
            }
            .padding(.top, 4)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var orderContentsSummary: String {
        let lines = order.orderDetails
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if lines.isEmpty {
            return "—"
        }
        return lines.joined(separator: " + ")
    }

    private var locationLine: String {
        if let loc = order.taskLocation, !loc.isEmpty {
            return loc
        }
        return order.restaurantName
    }

    private func relativePosted(_ date: Date?) -> String? {
        guard let date else { return nil }
        return Self.relFormatter.localizedString(for: date, relativeTo: Date())
    }

    private static let relFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()
}
