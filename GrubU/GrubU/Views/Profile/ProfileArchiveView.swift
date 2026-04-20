//
//  ProfileArchiveView.swift
//
//  Old finished stuff — jobs you ran and orders you ordered.
//
//  Created by Julie Baguio on 4/7/26.
//

import SwiftUI

struct ProfileArchiveView: View {
    @EnvironmentObject var activityController: ActivityController

    private var completedJobs: [Order] {
        activityController.fulfillingTasks.filter { $0.status == "completed" }
    }

    private var completedRequests: [Order] {
        activityController.requestedOrders.filter { $0.status == "completed" }
    }

    private var isEmpty: Bool {
        completedJobs.isEmpty && completedRequests.isEmpty
    }

    var body: some View {
        Group {
            if isEmpty {
                ContentUnavailableView(
                    "Nothing archived yet",
                    systemImage: "archivebox",
                    description: Text("Completed jobs and completed requests show up here.")
                )
            } else {
                List {
                    if !completedJobs.isEmpty {
                        Section("Jobs you completed") {
                            ForEach(completedJobs) { order in
                                let oid = order.id ?? ""
                                NavigationLink(destination: TaskTrackingView(order: order)) {
                                    OrderListRow(
                                        order: order,
                                        showsUnreadDot: activityController.unreadTaskOrderIds.contains(oid)
                                    )
                                }
                            }
                        }
                    }
                    if !completedRequests.isEmpty {
                        Section("Requests you made") {
                            ForEach(completedRequests) { order in
                                let oid = order.id ?? ""
                                NavigationLink(destination: RequestTrackingView(order: order)) {
                                    OrderListRow(
                                        order: order,
                                        showsUnreadDot: activityController.unreadRequestOrderIds.contains(oid)
                                    )
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Archive")
        .navigationBarTitleDisplayMode(.inline)
    }
}
