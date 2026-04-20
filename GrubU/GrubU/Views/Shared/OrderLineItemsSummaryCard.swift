//
//  OrderLineItemsSummaryCard.swift
//
//  Restaurant + line items with quantities (collapsed duplicate lines).
//
//  Created by Julie Baguio on 4/20/26.
//

import SwiftUI

struct OrderLineItemsSummaryCard: View {
    let order: Order

    private var aggregatedLines: [(text: String, count: Int)] {
        let trimmed = order.orderDetails
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var counts: [String: Int] = [:]
        var orderKeys: [String] = []
        for line in trimmed {
            if counts[line] == nil {
                orderKeys.append(line)
            }
            counts[line, default: 0] += 1
        }
        return orderKeys.compactMap { key in
            guard let c = counts[key] else { return nil }
            return (key, c)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Order")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .textCase(.uppercase)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: 6) {
                Text(order.restaurantName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let loc = order.taskLocation?.trimmingCharacters(in: .whitespacesAndNewlines), !loc.isEmpty {
                    Label(loc, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if aggregatedLines.isEmpty {
                Text("No line items listed.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(aggregatedLines.enumerated()), id: \.offset) { _, row in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\u{2022}")
                                .foregroundStyle(.secondary)
                            if row.count > 1 {
                                Text("\(row.count)×")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                            }
                            Text(row.text)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .profileModalCardStyle()
    }
}
