//
//  EarnAllActiveJobsView.swift
//
//  Full list of jobs you’re working on (tap into task tracker).
//
//  Created by Julie Baguio on 4/7/26.
//

import SwiftUI

private let earnActiveJobsListPadding: CGFloat = 20

struct EarnAllActiveJobsView: View {
    @EnvironmentObject var activityController: ActivityController

    private var activeJobs: [Order] {
        activityController.fulfillingTasks.filter { OrderStatusGroups.isActiveFulfiller($0.status) }
    }

    var body: some View {
        Group {
            if activeJobs.isEmpty {
                earnEmptyState
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(activeJobs) { order in
                            CompactFulfillerActiveOrderRow(
                                order: order,
                                showsUnreadDot: activityController.unreadTaskOrderIds.contains(order.id ?? "")
                            )
                        }
                    }
                    .padding(.horizontal, earnActiveJobsListPadding)
                    .padding(.top, 12)
                    .padding(.bottom, 16 + AppTheme.tabBarBottomClearance)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.accent)
        .navigationTitle(activeJobs.isEmpty ? "My Active Jobs" : "My Active Jobs (\(activeJobs.count))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.accent, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var earnEmptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "briefcase")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
            Text("No active jobs")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Accepted jobs appear here. Browse the Earn tab to claim open tasks.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.88))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, AppTheme.tabBarBottomClearance)
    }
}
