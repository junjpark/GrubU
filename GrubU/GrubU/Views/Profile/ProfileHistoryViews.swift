//
//  ProfileHistoryViews.swift
//
//  Split archive: completed jobs only vs completed requests only.
//
//  Created by Julie Baguio on 4/7/26.
//

import SwiftUI

// MARK: - Completed jobs archive

struct ProfileJobsArchiveView: View {
    @EnvironmentObject var activityController: ActivityController

    private var completedJobs: [Order] {
        activityController.fulfillingTasks.filter { $0.status == "completed" }
    }

    var body: some View {
        Group {
            if completedJobs.isEmpty {
                ContentUnavailableView(
                    "No completed jobs yet",
                    systemImage: "briefcase",
                    description: Text("Finished work you accepted shows up here.")
                )
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(completedJobs.indices, id: \.self) { index in
                            let order = completedJobs[index]
                            NavigationLink(destination: TaskTrackingView(order: order)) {
                                ArchiveOrderRow(order: order)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, ProfileLayout.horizontalPadding)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            if index < completedJobs.count - 1 {
                                Divider()
                                    .padding(.leading, ProfileLayout.horizontalPadding)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Completed jobs")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Completed requests archive

struct ProfileRequestsArchiveView: View {
    @EnvironmentObject var activityController: ActivityController

    private var completedRequests: [Order] {
        activityController.requestedOrders.filter { $0.status == "completed" }
    }

    var body: some View {
        Group {
            if completedRequests.isEmpty {
                ContentUnavailableView(
                    "No completed requests yet",
                    systemImage: "tray",
                    description: Text("Orders you posted that fully finished show up here.")
                )
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(completedRequests.indices, id: \.self) { index in
                            let order = completedRequests[index]
                            NavigationLink(destination: RequestTrackingView(order: order)) {
                                ArchiveOrderRow(order: order)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, ProfileLayout.horizontalPadding)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            if index < completedRequests.count - 1 {
                                Divider()
                                    .padding(.leading, ProfileLayout.horizontalPadding)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Completed requests")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Shared row (archive only; no status)

struct ArchiveOrderRow: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(order.restaurantName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                Text("$\(order.bountyAmount, specifier: "%.2f")")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Text(orderLineItemsSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let timestampText {
                Text(timestampText)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
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
