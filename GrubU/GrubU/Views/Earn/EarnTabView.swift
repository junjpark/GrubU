//
//  EarnTabView.swift
//
//  Earn tab: optional active jobs strip, then available requests feed.
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

    private var activeJobs: [Order] {
        activityController.fulfillingTasks.filter { OrderStatusGroups.isActiveFulfiller($0.status) }
    }

    private var previewJobs: [Order] {
        Array(activeJobs.prefix(2))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Turn extra meal points into real cash.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, earnHorizontalPadding)
                        .padding(.top, 14)
                        .padding(.bottom, 18)

                    if !activeJobs.isEmpty {
                        activeJobsSection
                    }

                    earnSectionTitle("Available Requests")
                        .padding(.horizontal, earnHorizontalPadding)
                        .padding(.top, activeJobs.isEmpty ? 0 : 10)

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
                        .padding(.bottom, 28)
                    }
                }
            }
            .scrollContentBackground(.hidden)
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
    }

    // MARK: - Active jobs (compact)

    private var activeJobsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("My Active Jobs (\(activeJobs.count))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .lineLimit(1)
                Spacer(minLength: 8)
                NavigationLink {
                    EarnAllActiveJobsView()
                } label: {
                    Text("View All")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, earnHorizontalPadding)
            .padding(.top, 12)

            VStack(spacing: 8) {
                ForEach(previewJobs) { order in
                    compactActiveJobRow(order)
                }
            }
            .padding(.horizontal, earnHorizontalPadding)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.accent)
    }

    @ViewBuilder
    private func compactActiveJobRow(_ order: Order) -> some View {
        let oid = order.id ?? ""
        let status = activeJobStatusPresentation(for: order.status)
        NavigationLink(destination: TaskTrackingView(order: order)) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(activeJobOrderSummary(order))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(4)

                    Text(activeJobPickupLine(order))
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
                        if activityController.unreadTaskOrderIds.contains(oid) {
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

    private func activeJobOrderSummary(_ order: Order) -> String {
        let lines = order.orderDetails
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if lines.isEmpty {
            return "—"
        }
        return lines.joined(separator: " + ")
    }

    /// Pickup / venue context (e.g. `Subway @ DUC` when a task location exists).
    private func activeJobPickupLine(_ order: Order) -> String {
        let name = order.restaurantName
        if let loc = order.taskLocation?.trimmingCharacters(in: .whitespacesAndNewlines), !loc.isEmpty {
            return "\(name) @ \(loc)"
        }
        return name
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

    private func activeJobStatusPresentation(for status: String) -> (label: String, color: Color) {
        switch status {
        case "claimed":
            return ("Need to Order", .red)
        case "ordered":
            return ("Order in Progress", Color(red: 0.78, green: 0.58, blue: 0.04))
        case "delivered":
            return ("Delivered", .green)
        case "completed":
            return ("Completed", .purple)
        default:
            return (status.replacingOccurrences(of: "_", with: " ").capitalized, .orange)
        }
    }
}
