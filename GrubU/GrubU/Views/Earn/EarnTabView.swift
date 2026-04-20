//
//  EarnTabView.swift
//
//  Earn tab: active job chips up top, open jobs to claim below.
//
//  Created by Julie Baguio on 4/7/26.
//

import SwiftUI
import FirebaseAuth

struct EarnTabView: View {
    @EnvironmentObject var tabState: TabState
    @EnvironmentObject var activityController: ActivityController
    @EnvironmentObject var authController: AuthController

    @StateObject private var marketController = MarketController()

    private var activeJobs: [Order] {
        activityController.fulfillingTasks.filter { OrderStatusGroups.isActiveFulfiller($0.status) }
    }

    private var stripJobs: [Order] {
        Array(activeJobs.prefix(5))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                earnActiveJobsHeader

                Divider()

                EarnBrowseView(marketController: marketController)
            }
            .navigationTitle("Earn")
            .background(Color(.systemGroupedBackground))
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

    private var earnActiveJobsHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HelperBannerView(
                storageKey: "grubu.helper.dismiss.earnBrowse",
                text: "Browse open jobs below. Your accepted jobs stay at the top for quick access."
            )
            .padding(.horizontal)

            Text("My active jobs")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)

            if activeJobs.isEmpty {
                Text("No jobs in progress — claim an open task below.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(stripJobs) { order in
                            activeJobChip(order)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
                }

                NavigationLink {
                    EarnAllActiveJobsView()
                } label: {
                    HStack {
                        Label(
                            activeJobs.count > 5
                                ? "View all active jobs (\(activeJobs.count))"
                                : "Job details & status",
                            systemImage: "list.bullet.rectangle"
                        )
                        .font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 4)
                .padding(.bottom, 6)
            }
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private func activeJobChip(_ order: Order) -> some View {
        let oid = order.id ?? ""
        NavigationLink(destination: TaskTrackingView(order: order)) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if activityController.unreadTaskOrderIds.contains(oid) {
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
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
