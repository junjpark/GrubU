//
//  ActivityMainView.swift
//  GrubU
//

import SwiftUI
import FirebaseAuth

struct ActivityMainView: View {
    @EnvironmentObject var authController: AuthController
    @ObservedObject var activityController: ActivityController
    @ObservedObject var tabState: TabState

    var requestBadge: Int {
        activityController.requestedOrders.filter { $0.status != "open" && $0.status != "completed" }.count
    }

    var taskBadge: Int {
        activityController.fulfillingTasks.filter { $0.status != "completed" }.count
    }

    var body: some View {
        NavigationView {
            VStack {
                Picker("Tab", selection: $tabState.activitySegment) {
                    Text(requestBadge > 0 ? "My Requests (\(requestBadge))" : "My Requests").tag(0)
                    Text(taskBadge > 0 ? "My Tasks (\(taskBadge))" : "My Tasks").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if tabState.activitySegment == 0 {
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
