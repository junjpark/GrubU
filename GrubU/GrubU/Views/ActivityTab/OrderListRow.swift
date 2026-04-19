//
//  OrderListRow.swift
//  GrubU
//
//  Created by user287016 on 4/7/26.
//

import SwiftUI

struct OrderListRow: View {
    let order: Order

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(order.restaurantName)
                    .font(.headline)
                Text(order.status.capitalized)
                    .font(.subheadline)
                    .foregroundColor(statusColor)
            }
            Spacer()
            Text("$\(order.bountyAmount, specifier: "%.2f")")
                .font(.title3)
                .bold()
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch order.status {
        case "delivered": return .green
        case "ordered": return .blue
        case "completed": return .purple
        default: return .orange
        }
    }
}
