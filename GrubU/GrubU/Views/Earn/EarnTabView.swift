//
//  EarnTabView.swift
//
//  Earn tab: optional active orders strip, then available requests feed.
//
//  Created by Julie Baguio on 4/7/26.
//

import SwiftUI
import FirebaseAuth

private let earnHorizontalPadding: CGFloat = 20

struct EarnTabView: View {
    @EnvironmentObject var tabState: TabState
    @EnvironmentObject var activityController: ActivityController
    @EnvironmentObject var authController: AuthController

    @StateObject private var marketController = MarketController()
    @StateObject private var earnPostClaimNavigation = EarnNavigationCoordinator()

    private var activeOrders: [Order] {
        activityController.fulfillingTasks.filter { OrderStatusGroups.isActiveFulfiller($0.status) }
    }

    private var previewOrders: [Order] {
        Array(activeOrders.prefix(1))
    }

    private var postClaimOrderBinding: Binding<Order?> {
        Binding(
            get: { earnPostClaimNavigation.postClaimOrder },
            set: { earnPostClaimNavigation.postClaimOrder = $0 }
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Pinned: orange active-orders strip always shows (mirrors Request tab’s pinned strip).
                activeOrdersSection
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.accent)

                VStack(alignment: .leading, spacing: 0) {
                    earnSectionTitle("Available Requests")
                        .padding(.horizontal, earnHorizontalPadding)
                        .padding(.top, 10)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            if marketController.openOrders.isEmpty {
                                earnEmptyState
                                    .padding(.horizontal, earnHorizontalPadding)
                                    .padding(.top, 8)
                            } else {
                                VStack(spacing: 0) {
                                    let orders = marketController.openOrders
                                    ForEach(Array(orders.enumerated()), id: \.element.id) { index, order in
                                        NavigationLink(destination: OrderPreviewView(order: order)) {
                                            EarnAvailableRequestCard(order: order)
                                        }
                                        .buttonStyle(.plain)

                                        if index < orders.count - 1 {
                                            Divider()
                                                .background(Color(.separator).opacity(0.55))
                                                .padding(.vertical, 12)
                                        }
                                    }
                                }
                                .padding(.horizontal, earnHorizontalPadding)
                                .padding(.top, 8)
                                .padding(.bottom, 28)
                            }
                        }
                        .padding(.bottom, AppTheme.tabBarBottomClearance)
                    }
                    .scrollContentBackground(.hidden)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.pageBackground)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(AppTheme.pageBackground)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let uid = authController.userSession?.uid {
                    activityController.fetchActivity(for: uid)
                }
                marketController.fetchOpenOrders()
            }
            .onDisappear {
                marketController.stopListening()
            }
        }
        .navigationDestination(item: postClaimOrderBinding) { order in
            TaskTrackingView(order: order)
        }
        .environment(\.earnPostClaimNavigation, earnPostClaimNavigation)
    }

    // MARK: - Active orders (compact)

    private var activeOrdersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("My Active Orders (\(activeOrders.count))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .lineLimit(1)
                Spacer(minLength: 8)
                if !activeOrders.isEmpty {
                    NavigationLink {
                        EarnAllActiveOrdersView()
                    } label: {
                        Text("View All")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, earnHorizontalPadding)
            .padding(.top, 12)

            if activeOrders.isEmpty {
                Text("Got extra meal points? Turn them into real cash by fulfilling requests.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.92))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, earnHorizontalPadding)
                    .padding(.bottom, 16)
            } else {
                VStack(spacing: 8) {
                    ForEach(previewOrders) { order in
                        CompactFulfillerActiveOrderRow(
                            order: order,
                            showsUnreadDot: activityController.unreadTaskOrderIds.contains(order.id ?? "")
                        )
                    }
                }
                .padding(.horizontal, earnHorizontalPadding)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.accent)
    }

    // MARK: - Empty available requests

    private var earnEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 44))
                .foregroundStyle(.secondary.opacity(0.45))
            Text("Nothing available right now.")
                .font(.headline)
            Text("Check back soon or try requesting help.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                tabState.selectedTab = 1
            } label: {
                Text("Switch to Request")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    /// Matches `ProfileView` section headers (Activity / Settings).
    private func earnSectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.accent)
            .textCase(.uppercase)
            .tracking(0.6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
            .padding(.bottom, 10)
    }
}
