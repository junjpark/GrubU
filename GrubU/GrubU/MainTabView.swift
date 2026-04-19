//
//  MainTabView.swift
//  GrubU
//
//  Created by user287016 on 4/7/26.
//
import SwiftUI
import FirebaseAuth
import Combine

class TabState: ObservableObject {
    @Published var selectedTab = 0
    @Published var activitySegment = 0
}

struct MainTabView: View {
    @StateObject private var tabState = TabState()
    @EnvironmentObject var authController: AuthController
    @StateObject private var activityController = ActivityController()

    var activityBadgeCount: Int {
        let requestUpdates = activityController.requestedOrders.filter { $0.status != "open" && $0.status != "completed" }.count
        let taskUpdates = activityController.fulfillingTasks.filter { $0.status != "completed" }.count
        return requestUpdates + taskUpdates
    }

    var body: some View {
        TabView(selection: $tabState.selectedTab) {

            MarketFeedView()
                .tabItem {
                    Label("Market", systemImage: "cart.fill")
                }
                .tag(0)

            NewRequestView()
                .tabItem {
                    Label("Request", systemImage: "plus.circle.fill")
                }
                .tag(1)

            ActivityMainView(activityController: activityController, tabState: tabState)
                .tabItem {
                    Label("Activity", systemImage: "arrow.up.arrow.down.circle.fill")
                }
                .badge(activityBadgeCount > 0 ? activityBadgeCount : 0)
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .accentColor(.orange)
        .environmentObject(tabState)
        .onAppear {
            if let uid = authController.userSession?.uid {
                activityController.fetchActivity(for: uid)
            }
        }
    }
}
