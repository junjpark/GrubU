//
//  MainTabView.swift
//
//  Earn / Request / Profile with a full-width custom tab bar.
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
    /// Lives at tab root so nested `NavigationStack` + checkout still resolve `OrderReviewView`’s `@EnvironmentObject`.
    @StateObject private var requestNavigation = RequestNavigationCoordinator()

    var body: some View {
        Group {
            switch tabState.selectedTab {
            case 0:
                EarnTabView()
            case 1:
                RequestHubView()
            case 2:
                ProfileView()
            default:
                EarnTabView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            fullWidthTabBar
        }
        .accentColor(.orange)
        .environmentObject(tabState)
        .environmentObject(activityController)
        .environmentObject(requestNavigation)
        .onAppear {
            if let uid = authController.userSession?.uid {
                activityController.fetchActivity(for: uid)
            }
        }
    }

    private var fullWidthTabBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color(.separator))

            HStack(spacing: 0) {
                tabItem(
                    index: 0,
                    title: "Earn",
                    systemImage: "banknote.fill"
                )
                tabItem(
                    index: 1,
                    title: "Request",
                    systemImage: "fork.knife"
                )
                tabItem(
                    index: 2,
                    title: "Profile",
                    systemImage: "person.fill"
                )
            }
            .padding(.top, 8)
            .padding(.bottom, 10)
            .background(AppTheme.pageBackground)
        }
        .background(AppTheme.pageBackground)
    }

    private func tabItem(index: Int, title: String, systemImage: String) -> some View {
        let selected = tabState.selectedTab == index
        return Button {
            tabState.selectedTab = index
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: selected ? .semibold : .regular))
                Text(title)
                    .font(.caption2.weight(selected ? .semibold : .regular))
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(selected ? AppTheme.accent : Color.primary.opacity(0.45))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
