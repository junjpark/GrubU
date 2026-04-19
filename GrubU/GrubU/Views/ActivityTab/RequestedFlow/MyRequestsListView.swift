//
//  MyRequestsListView.swift
//
//
//  Created by Julie Baguio on 4/7/26.
//
import SwiftUI

struct MyRequestsListView: View {
    @EnvironmentObject var activityController: ActivityController
    let orders: [Order]

    var body: some View {
        List(orders) { order in
            let oid = order.id ?? ""
            NavigationLink(destination: RequestTrackingView(order: order)) {
                OrderListRow(
                    order: order,
                    showsUnreadDot: activityController.unreadRequestOrderIds.contains(oid)
                )
            }
        }
        .listStyle(.plain)
    }
}
