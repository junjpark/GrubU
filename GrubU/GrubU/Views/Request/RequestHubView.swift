//
//  RequestHubView.swift
//
//  Request tab: active chips on top, restaurant + bag flow under that.
//
//  Created by Julie Baguio on 4/7/26.
//

import SwiftUI
import FirebaseAuth

struct RequestHubView: View {
    @EnvironmentObject var tabState: TabState
    @EnvironmentObject var activityController: ActivityController
    @EnvironmentObject var authController: AuthController

    @StateObject private var menuManager = MenuManager()

    private var activeRequests: [Order] {
        activityController.requestedOrders.filter { OrderStatusGroups.isActiveRequester($0.status) }
    }

    private var stripRequests: [Order] {
        Array(activeRequests.prefix(5))
    }

    private var completedRequests: [Order] {
        activityController.requestedOrders.filter { $0.status == "completed" }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                myRequestsHeader

                Divider()

                NewRequestView(menuManager: menuManager)
            }
            .navigationTitle("Request")
            .onAppear {
                if let uid = authController.userSession?.uid {
                    activityController.fetchActivity(for: uid)
                }
            }
        }
    }

    private var myRequestsHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HelperBannerView(
                storageKey: "requestTab",
                text: "Post a request and students nearby can help you."
            )
            .padding(.horizontal)

            Text("My active requests")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)

            if activeRequests.isEmpty {
                Text(completedRequests.isEmpty
                     ? "None yet — pick a restaurant below to post your first order."
                     : "No active requests. Completed orders are in Profile › Archive.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(stripRequests) { order in
                            activeRequestChip(order)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
                }

                NavigationLink {
                    RequestAllActiveRequestsView()
                } label: {
                    HStack {
                        Label(
                            activeRequests.count > 5
                                ? "View all active requests (\(activeRequests.count))"
                                : "Request details & status",
                            systemImage: "list.bullet.rectangle"
                        )
                        .font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                    .background(AppTheme.surfaceBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 4)
                .padding(.bottom, 6)
            }
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.pageBackground)
    }

    @ViewBuilder
    private func activeRequestChip(_ order: Order) -> some View {
        let oid = order.id ?? ""
        NavigationLink(destination: RequestTrackingView(order: order)) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if activityController.unreadRequestOrderIds.contains(oid) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                    }
                    Text(order.restaurantName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Text(order.status.capitalized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("$\(order.bountyAmount, specifier: "%.2f")")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }
            .padding(10)
            .frame(width: 148, alignment: .leading)
            .background(AppTheme.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
