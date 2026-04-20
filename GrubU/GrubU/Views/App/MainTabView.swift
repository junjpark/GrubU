//
//  MainTabView.swift
//
//  Tab bar: Earn / Request / Profile + shared state wired in.
//
//  Created by user287016 on 4/7/26.
//
import SwiftUI
import Combine
import FirebaseAuth

class TabState: ObservableObject {
    /// 0 = Earn, 1 = Request, 2 = Profile
    @Published var selectedTab = 0
}

struct MainTabView: View {
    @EnvironmentObject var authController: AuthController
    @StateObject private var tabState = TabState()
    @StateObject private var activityController = ActivityController()
    @State private var appliedIntentDefault = false

    var body: some View {
        TabView(selection: $tabState.selectedTab) {
            EarnTabView()
                .tabItem {
                    Label("Earn", systemImage: "dollarsign.circle.fill")
                }
                .tag(0)

            RequestHubView()
                .tabItem {
                    Label("Request", systemImage: "tray.and.arrow.down.fill")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
        }
        .accentColor(.orange)
        .environmentObject(tabState)
        .environmentObject(activityController)
        .onAppear {
            if let uid = authController.userSession?.uid {
                activityController.fetchActivity(for: uid)
                if !appliedIntentDefault, let intent = UserIntentStore.intent(for: uid) {
                    tabState.selectedTab = UserIntentStore.defaultTabIndex(for: intent)
                    appliedIntentDefault = true
                }
            }
        }
    }
}
