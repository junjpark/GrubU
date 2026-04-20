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

    private var activeRequests: [Order] {
        activityController.requestedOrders.filter { OrderStatusGroups.isActiveRequester($0.status) }
    }

    private var previewRequests: [Order] {
        Array(activeRequests.prefix(2))
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

                Divider()

                NewRequestView(menuManager: menuManager)
            }
            .background(AppTheme.pageBackground)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let uid = authController.userSession?.uid {
                    activityController.fetchActivity(for: uid)
                }
            }
        }
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
        let oid = order.id ?? ""
        let status = requesterStatusPresentation(for: order.status)
        NavigationLink(destination: RequestTrackingView(order: order)) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(compactRequestOrderSummary(order))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(4)

                    Text(compactRequestPickupLine(order))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 6) {
                    Text(status.label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(status.color)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        if activityController.unreadRequestOrderIds.contains(oid) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppTheme.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func compactRequestOrderSummary(_ order: Order) -> String {
        let lines = order.orderDetails
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if lines.isEmpty {
            return "—"
        }
        return lines.joined(separator: " + ")
    }

    private func compactRequestPickupLine(_ order: Order) -> String {
        let name = order.restaurantName
        if let loc = order.taskLocation?.trimmingCharacters(in: .whitespacesAndNewlines), !loc.isEmpty {
            return "\(name) @ \(loc)"
        }
        return name
    }

    /// Requester-facing status line (styling only; same layout as Earn active jobs).
    private func requesterStatusPresentation(for status: String) -> (label: String, color: Color) {
        switch status {
        case "open":
            return ("Posted", AppTheme.accent)
        case "claimed":
            return ("Matched", .blue)
        case "ordered":
            return ("Order in Progress", Color(red: 0.78, green: 0.58, blue: 0.04))
        case "delivered":
            return ("Ready for you", .green)
        case "completed":
            return ("Completed", .purple)
        default:
            return (status.replacingOccurrences(of: "_", with: " ").capitalized, .orange)
        }
    }
}
