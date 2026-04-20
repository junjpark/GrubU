//
//  RequestHubView.swift
//
//  Request tab: blurb + active requests strip (Earn-style), then restaurant flow.
//
//  Created by Julie Baguio on 4/7/26.
//

import SwiftUI
import FirebaseAuth

private let requestHorizontalPadding: CGFloat = 20

struct RequestHubView: View {
    @EnvironmentObject var activityController: ActivityController
    @EnvironmentObject var authController: AuthController

    @StateObject private var menuManager = MenuManager()
    @EnvironmentObject private var requestNavigation: RequestNavigationCoordinator

    private var activeRequests: [Order] {
        activityController.requestedOrders.filter { OrderStatusGroups.isActiveRequester($0.status) }
    }

    private var previewRequests: [Order] {
        Array(activeRequests.prefix(1))
    }

    private var completedRequests: [Order] {
        activityController.requestedOrders.filter { $0.status == "completed" }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Out of meal points? Set your price and get a meal.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, requestHorizontalPadding)
                        .padding(.top, 14)
                        .padding(.bottom, 18)

                    if !activeRequests.isEmpty {
                        activeRequestsSection
                    } else {
                        requestActiveEmptyCallout
                            .padding(.horizontal, requestHorizontalPadding)
                            .padding(.bottom, 12)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.pageBackground)

                VStack(alignment: .leading, spacing: 0) {
                    requestMealSectionHeader
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, ProfileLayout.horizontalPadding)

                    NavigationStack {
                        NewRequestView(menuManager: menuManager)
                            .frame(maxWidth: .infinity)
                    }
                    .id(requestNavigation.browseResetToken)
                }
                .frame(maxWidth: .infinity)
                .background(AppTheme.pageBackground)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(AppTheme.pageBackground)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $requestNavigation.orderToTrackAfterPost) { order in
                RequestTrackingView(order: order)
            }
            .onAppear {
                if let uid = authController.userSession?.uid {
                    activityController.fetchActivity(for: uid)
                }
            }
        }
    }

    // MARK: - Request a meal (Profile-style section)

    /// Same typography and accent treatment as `ProfileView.sectionTitle`.
    private var requestMealSectionHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "fork.knife")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
            Text("Request a Meal")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .textCase(.uppercase)
                .tracking(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    // MARK: - Active requests (matches Earn “My Active Jobs” strip)

    private var activeRequestsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("My Active Requests (\(activeRequests.count))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .lineLimit(1)
                Spacer(minLength: 8)
                NavigationLink {
                    RequestAllActiveRequestsView()
                } label: {
                    Text("View All")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, requestHorizontalPadding)
            .padding(.top, 12)

            VStack(spacing: 8) {
                ForEach(previewRequests) { order in
                    compactActiveRequestRow(order)
                }
            }
            .padding(.horizontal, requestHorizontalPadding)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.accent)
    }

    private var requestActiveEmptyCallout: some View {
        Text(
            completedRequests.isEmpty
                ? "None yet — pick a restaurant below to post your first order."
                : "No active requests. Completed orders are in Profile › Archive."
        )
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func compactActiveRequestRow(_ order: Order) -> some View {
        CompactRequesterActiveOrderRow(
            order: order,
            showsUnreadDot: activityController.unreadRequestOrderIds.contains(order.id ?? "")
        )
    }
}
