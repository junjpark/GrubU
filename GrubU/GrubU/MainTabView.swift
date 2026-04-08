//
//  MainTabView.swift
//  GrubU
//
//  Created by user287016 on 4/7/26.
//
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
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
            
            ActivityMainView()
                .tabItem {
                    Label("Activity", systemImage: "arrow.up.arrow.down.circle.fill")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .accentColor(.orange)
    }
}
