//
//  ProfileHistoryViews.swift
//
//  Split archive: completed orders only vs completed requests only.
//
//  Created by Julie Baguio on 4/7/26.
//

import SwiftUI

// MARK: - Completed orders archive

struct ProfileOrdersArchiveView: View {
    @EnvironmentObject var activityController: ActivityController

    private var completedOrders: [Order] {
        activityController.fulfillingTasks.filter { $0.status == "completed" }
    }

    var body: some View {
        ProfileArchiveScreen(
            title: "Completed orders",
            sectionTitle: "Order history",
            sectionIcon: "bag.fill",
            orders: completedOrders,
            emptyTitle: "No completed orders yet",
            emptyMessage: "Orders you accepted and finished show up here.",
            emptyIcon: "bag",
            destination: { order in AnyView(TaskTrackingView(order: order)) }
        )
    }
}

// MARK: - Completed requests archive

struct ProfileRequestsArchiveView: View {
    @EnvironmentObject var activityController: ActivityController

    private var completedRequests: [Order] {
        activityController.requestedOrders.filter { $0.status == "completed" }
    }

    var body: some View {
        ProfileArchiveScreen(
            title: "Completed requests",
            sectionTitle: "Request history",
            sectionIcon: "tray.full.fill",
            orders: completedRequests,
            emptyTitle: "No completed requests yet",
            emptyMessage: "Orders you posted that fully finished show up here.",
            emptyIcon: "tray",
            destination: { order in AnyView(RequestTrackingView(order: order)) }
        )
    }
}

// MARK: - Shared archive screen (Profile chrome)

private struct ProfileArchiveScreen: View {
    let title: String
    let sectionTitle: String
    let sectionIcon: String
    let orders: [Order]
    let emptyTitle: String
    let emptyMessage: String
    let emptyIcon: String
    let destination: (Order) -> AnyView

    var body: some View {
        Group {
            if orders.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ProfileSectionHeader(title: "\(sectionTitle) (\(orders.count))", systemImage: sectionIcon)

                        VStack(spacing: 0) {
                            ForEach(Array(orders.enumerated()), id: \.1.id) { index, order in
                                NavigationLink {
                                    destination(order)
                                } label: {
                                    ProfileArchiveOrderRow(order: order)
                                }
                                .buttonStyle(.plain)

                                if index < orders.count - 1 {
                                    Divider()
                                        .background(Color(.separator))
                                }
                            }
                        }
                        .profileModalCardStyle()

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, ProfileLayout.horizontalPadding)
                    .padding(.top, 18)
                    .padding(.bottom, AppTheme.tabBarBottomClearance)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.pageBackground)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: emptyIcon)
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(AppTheme.accent.opacity(0.85))
            Text(emptyTitle)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(emptyMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, AppTheme.tabBarBottomClearance)
    }
}

// MARK: - Archive row (matches Profile’s row typography)

private struct ProfileArchiveOrderRow: View {
    let order: Order

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(order.restaurantName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(orderLineItemsSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let timestampText {
                    Text(timestampText)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "$%.2f", order.bountyAmount))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .monospacedDigit()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }

    private var orderLineItemsSummary: String {
        let lines = order.orderDetails
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let placeholderPhrases = ["(no additional notes)", "(no additional notes.)"]
        let meaningful = lines.filter { line in
            !placeholderPhrases.contains(line.lowercased())
        }

        if meaningful.isEmpty {
            return "No line items listed"
        }
        return meaningful.joined(separator: " · ")
    }

    private var timestampText: String? {
        guard let date = order.createdAt else { return nil }
        return Self.formatter.string(from: date)
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.doesRelativeDateFormatting = true
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
}

enum ProfileLayout {
    static let horizontalPadding: CGFloat = 20
}
