//
//  EarnAllActiveJobsView.swift
//
//  Full list of jobs you’re working on (tap into task tracker).
//
//  Created by Julie Baguio on 4/7/26.
//

import SwiftUI

struct EarnAllActiveJobsView: View {
    @EnvironmentObject var activityController: ActivityController

    private var activeJobs: [Order] {
        activityController.fulfillingTasks.filter { OrderStatusGroups.isActiveFulfiller($0.status) }
    }

    var body: some View {
        Group {
            if activeJobs.isEmpty {
                ContentUnavailableView(
                    "No active jobs",
                    systemImage: "briefcase",
                    description: Text("Accepted work appears here. Browse the Earn tab to claim open tasks.")
                )
            } else {
                List(activeJobs) { order in
                    let oid = order.id ?? ""
                    NavigationLink(destination: TaskTrackingView(order: order)) {
                        OrderListRow(
                            order: order,
                            showsUnreadDot: activityController.unreadTaskOrderIds.contains(oid)
                        )
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Active jobs")
        .navigationBarTitleDisplayMode(.inline)
    }
}
