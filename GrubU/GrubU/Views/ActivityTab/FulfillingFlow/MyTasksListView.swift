//
//  MyTasksListView.swift
//  
//
//  Created by Julie Baguio on 4/7/26.
//
import SwiftUI

struct MyTasksListView: View {
    let orders: [Order]
    
    var body: some View {
        List(orders) { order in
            NavigationLink(destination: TaskTrackingView(order: order)) {
                OrderListRow(order: order)
            }
        }
        .listStyle(.plain)
    }
}
