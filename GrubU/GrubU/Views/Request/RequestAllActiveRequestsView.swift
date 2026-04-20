//
//  RequestAllActiveRequestsView.swift
//
//  Every in-flight request you posted, in one scrollable list.
//
//  Created by Julie Baguio on 4/7/26.
//

import SwiftUI

struct RequestAllActiveRequestsView: View {
    @EnvironmentObject var activityController: ActivityController

    private var activeRequests: [Order] {
        activityController.requestedOrders.filter { OrderStatusGroups.isActiveRequester($0.status) }
    }

    var body: some View {
        Group {
            if activeRequests.isEmpty {
                ContentUnavailableView(
                    "No active requests",
                    systemImage: "tray",
                    description: Text("Post a new order from the Request tab when you are ready.")
                )
            } else {
                List(activeRequests) { order in
                    let oid = order.id ?? ""
                    NavigationLink(destination: RequestTrackingView(order: order)) {
                        OrderListRow(
                            order: order,
                            showsUnreadDot: activityController.unreadRequestOrderIds.contains(oid)
                        )
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Active requests")
        .navigationBarTitleDisplayMode(.inline)
    }
}
