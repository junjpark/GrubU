//
//  MainTabView.swift
//  GrubU
//
//  Created by user287016 on 4/7/26.
//
import SwiftUI

class TabState: ObservableObject {
    @Published var selectedTab = 0
    @Published var activitySegment = 0
}

struct MainTabView: View {
    @StateObject private var tabState = TabState()
    @EnvironmentObject var authController: AuthController
    @StateObject private var activityController = ActivityController()

    private var activityTabDot: Bool {
        activityController.hasAnyUnreadActivity
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
                    ZStack(alignment: .topTrailing) {
                        Label("Activity", systemImage: "arrow.up.arrow.down.circle.fill")
                        if activityTabDot {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 12, y: -6)
                                .accessibilityLabel("Unread activity")
                        }
                    }
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .accentColor(.orange)
        .environmentObject(tabState)
        .environmentObject(activityController)
        .onAppear {
            if let uid = authController.userSession?.uid {
                activityController.fetchActivity(for: uid)
            }
        }
    }
}
