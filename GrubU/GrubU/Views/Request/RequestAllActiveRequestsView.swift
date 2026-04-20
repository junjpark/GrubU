//
//  RequestAllActiveRequestsView.swift
//
//  Every in-flight request you posted, in one scrollable list.
//
//  Created by Julie Baguio on 4/7/26.
//

import SwiftUI

private let requestActiveListPadding: CGFloat = 20

struct RequestAllActiveRequestsView: View {
    @EnvironmentObject var activityController: ActivityController

    private var activeRequests: [Order] {
        activityController.requestedOrders.filter { OrderStatusGroups.isActiveRequester($0.status) }
    }

    var body: some View {
        Group {
            if activeRequests.isEmpty {
                requestEmptyState
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(activeRequests) { order in
                            CompactRequesterActiveOrderRow(
                                order: order,
                                showsUnreadDot: activityController.unreadRequestOrderIds.contains(order.id ?? "")
                            )
                        }
                    }
                    .padding(.horizontal, requestActiveListPadding)
                    .padding(.top, 12)
                    .padding(.bottom, 16 + AppTheme.tabBarBottomClearance)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.accent)
        .navigationTitle(activeRequests.isEmpty ? "My Active Requests" : "My Active Requests (\(activeRequests.count))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.accent, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var requestEmptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "tray")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
            Text("No active requests")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Post a new order from the Request tab when you are ready.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.88))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, AppTheme.tabBarBottomClearance)
    }
}
