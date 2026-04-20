//
//  ActiveOrderStripRowViews.swift
//
//  Shared compact rows for fulfiller vs requester active strips (Earn + Request tabs, “View all”).
//
//  Created by Julie Baguio on 4/20/26.
//

import SwiftUI

enum ActiveOrderStripFormatting {
    static func orderLineSummary(_ order: Order) -> String {
        let lines = order.orderDetails
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if lines.isEmpty {
            return "—"
        }
        return lines.joined(separator: " + ")
    }

    static func pickupContextLine(order: Order) -> String {
        let name = order.restaurantName
        if let loc = order.taskLocation?.trimmingCharacters(in: .whitespacesAndNewlines), !loc.isEmpty {
            return "\(name) @ \(loc)"
        }
        return name
    }
}

/// Same card as the Earn tab “My Active Jobs” strip.
struct CompactFulfillerActiveOrderRow: View {
    let order: Order
    let showsUnreadDot: Bool

    var body: some View {
        let label = OrderStatusPresentation.shortLabel(status: order.status, role: .fulfiller)
        let color = OrderStatusPresentation.accentColor(status: order.status, role: .fulfiller)

        NavigationLink(destination: TaskTrackingView(order: order)) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ActiveOrderStripFormatting.orderLineSummary(order))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(4)

                    Text(ActiveOrderStripFormatting.pickupContextLine(order: order))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 6) {
                    Text(label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(color)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        if showsUnreadDot {
                            Circle()
                                .fill(AppTheme.accent)
                                .frame(width: 6, height: 6)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppTheme.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// Same card as the Request tab “My Active Requests” strip.
struct CompactRequesterActiveOrderRow: View {
    let order: Order
    let showsUnreadDot: Bool

    var body: some View {
        let label = OrderStatusPresentation.shortLabel(status: order.status, role: .requester)
        let color = OrderStatusPresentation.accentColor(status: order.status, role: .requester)

        NavigationLink(destination: RequestTrackingView(order: order)) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ActiveOrderStripFormatting.orderLineSummary(order))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(4)

                    Text(ActiveOrderStripFormatting.pickupContextLine(order: order))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 6) {
                    Text(label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(color)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        if showsUnreadDot {
                            Circle()
                                .fill(AppTheme.accent)
                                .frame(width: 6, height: 6)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppTheme.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
