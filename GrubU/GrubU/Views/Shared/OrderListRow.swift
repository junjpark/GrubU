//
//  OrderListRow.swift
//
//  One row for lists: title, status tint, optional red dot.
//
//  Created by user287016 on 4/7/26.
//

import SwiftUI

struct OrderListRow: View {
    let order: Order
    var showsUnreadDot: Bool = false
    var role: OrderStatusRole

    var body: some View {
        HStack(spacing: 10) {
            if showsUnreadDot {
                Circle()
                    .fill(AppTheme.accent)
                    .frame(width: 8, height: 8)
                    .accessibilityLabel("Unread status update")
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(order.restaurantName)
                    .font(.headline)
                Text(OrderStatusPresentation.shortLabel(status: order.status, role: role))
                    .font(.subheadline)
                    .foregroundColor(statusColor)
                if let timestampText = timestampText {
                    Text(timestampText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Text("$\(order.bountyAmount, specifier: "%.2f")")
                .font(.title3)
                .bold()
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        OrderStatusPresentation.accentColor(status: order.status, role: role)
    }

    private var timestampText: String? {
        guard let date = order.createdAt else { return nil }
        return Self.formatter.string(from: date)
    }

    /// Shared formatter so we don't allocate one per row render.
    /// Examples: "Today at 3:45 PM", "Yesterday at 10:02 AM", "Apr 17 at 9:13 PM".
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.doesRelativeDateFormatting = true
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
}
