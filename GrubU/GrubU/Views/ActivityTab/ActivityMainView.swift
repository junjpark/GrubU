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
