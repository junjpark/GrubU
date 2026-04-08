//
//  ActivityMainView.swift
//  GrubU
//

import SwiftUI
import FirebaseAuth

struct ActivityMainView: View {
    @EnvironmentObject var authController: AuthController
    @StateObject private var activityController = ActivityController()
    @State private var selection = 0 // 0 = Requested, 1 = Fulfilling
    
    var body: some View {
        NavigationView {
            VStack {
                // The Segmented Control
                Picker("Tab", selection: $selection) {
                    Text("My Requests").tag(0)
                    Text("My Tasks").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // The Traffic Cop: Route to the correct separated List View
                if selection == 0 {
                    MyRequestsListView(orders: activityController.requestedOrders)
                } else {
                    MyTasksListView(orders: activityController.fulfillingTasks)
                }
            }
            .navigationTitle("Activity")
            .onAppear {
                if let uid = authController.userSession?.uid {
                    activityController.fetchActivity(for: uid)
                }
            }
        }
    }
}

// MARK: - Extracted List Views

struct MyTasksListView: View {
    let orders: [Order]
    
    var body: some View {
        List(orders) { order in
            // Direct route to the TaskTrackingView we just built
            NavigationLink(destination: TaskTrackingView(order: order)) {
                OrderListRow(order: order)
            }
        }
        .listStyle(.plain)
    }
}

struct MyRequestsListView: View {
    let orders: [Order]
    
    var body: some View {
        List(orders) { order in
            // Direct route to the RequestTrackingView (Requester side)
            NavigationLink(destination: RequestTrackingView(order: order)) {
                OrderListRow(order: order)
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Reusable UI Component

// Extracted the row design so you don't write it twice!
struct OrderListRow: View {
    let order: Order
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(order.restaurantName)
                    .font(.headline)
                Text(order.status.capitalized)
                    .font(.subheadline)
                    .foregroundColor(statusColor)
            }
            Spacer()
            Text("$\(order.bountyAmount, specifier: "%.2f")")
                .bold()
        }
        .padding(.vertical, 4)
    }
    
    // Optional: Make the text color dynamic based on status
    private var statusColor: Color {
        switch order.status {
        case "delivered": return .green
        case "ordered": return .blue
        default: return .orange
        }
    }
}
