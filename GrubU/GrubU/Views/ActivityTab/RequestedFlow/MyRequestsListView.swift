//
//  MyRequestsListView.swift
//  
//
//  Created by Julie Baguio on 4/7/26.
//
import SwiftUI

struct MyRequestsListView: View {
    let orders: [Order]
    
    var body: some View {
        List(orders) { order in
            NavigationLink(destination: RequestTrackingView(order: order)) {
                OrderListRow(order: order)
            }
        }
        .listStyle(.plain)
    }
}
