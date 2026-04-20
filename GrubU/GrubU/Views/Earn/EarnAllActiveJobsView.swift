//
//  EarnAllActiveOrdersView.swift
//
//  Full list of orders you’re working on (tap into task tracker).
//
//  Created by Julie Baguio on 4/7/26.
//

import SwiftUI

private let earnActiveOrdersListPadding: CGFloat = 20

struct EarnAllActiveOrdersView: View {
    @EnvironmentObject var activityController: ActivityController

    private var activeOrders: [Order] {
        activityController.fulfillingTasks.filter { OrderStatusGroups.isActiveFulfiller($0.status) }
    }

    var body: some View {
        Group {
            if activeOrders.isEmpty {
                earnEmptyState
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(activeOrders) { order in
                            CompactFulfillerActiveOrderRow(
                                order: order,
                                showsUnreadDot: activityController.unreadTaskOrderIds.contains(order.id ?? "")
                            )
                        }
                    }
                    .padding(.horizontal, earnActiveOrdersListPadding)
                    .padding(.top, 12)
                    .padding(.bottom, 16 + AppTheme.tabBarBottomClearance)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.accent)
        .navigationTitle(activeOrders.isEmpty ? "My Active Orders" : "My Active Orders (\(activeOrders.count))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.accent, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var earnEmptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "bag")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
            Text("No active orders")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Accepted orders appear here. Browse the Earn tab to claim open requests.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.88))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, AppTheme.tabBarBottomClearance)
    }
}
