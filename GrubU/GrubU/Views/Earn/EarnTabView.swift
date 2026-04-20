//
//  EarnTabView.swift
//
//  Earn tab: optional active jobs strip, then available requests feed.
//
//  Created by Julie Baguio on 4/7/26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

private let earnHorizontalPadding: CGFloat = 20

/// Earn tab is gated behind Stripe Connect onboarding so unregistered accounts
/// can't browse jobs or bounty values they aren't allowed to accept.
private enum EarnStripeGateState: Equatable {
    case loading
    case needsConnect
    case connected
}

struct EarnTabView: View {
    @EnvironmentObject var tabState: TabState
    @EnvironmentObject var activityController: ActivityController
    @EnvironmentObject var authController: AuthController

    @StateObject private var marketController = MarketController()
    @StateObject private var earnPostClaimNavigation = EarnNavigationCoordinator()

    @State private var gateState: EarnStripeGateState = .loading
    @State private var showConnectSetup = false

    private var activeJobs: [Order] {
        activityController.fulfillingTasks.filter { OrderStatusGroups.isActiveFulfiller($0.status) }
    }

    private var previewJobs: [Order] {
        Array(activeJobs.prefix(1))
    }

    private var postClaimOrderBinding: Binding<Order?> {
        Binding(
            get: { earnPostClaimNavigation.postClaimOrder },
            set: { earnPostClaimNavigation.postClaimOrder = $0 }
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                switch gateState {
                case .loading:
                    earnLoadingView
                case .needsConnect:
                    earnLockedView
                case .connected:
                    connectedContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(AppTheme.pageBackground)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                refreshStripeStatus()
            }
            .onDisappear {
                marketController.stopListening()
            }
            .sheet(isPresented: $showConnectSetup, onDismiss: {
                refreshStripeStatus()
            }) {
                NavigationView {
                    BankLinkView()
                        .navigationTitle("Setup Required")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") { showConnectSetup = false }
                            }
                        }
                }
            }
        }
        .navigationDestination(item: postClaimOrderBinding) { order in
            TaskTrackingView(order: order)
        }
        .environment(\.earnPostClaimNavigation, earnPostClaimNavigation)
    }

    private var connectedContent: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                if !activeJobs.isEmpty {
                    activeJobsSection
                        .padding(.top, 14)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.pageBackground)

            VStack(alignment: .leading, spacing: 0) {
                earnSectionTitle("Available Requests")
                    .padding(.horizontal, earnHorizontalPadding)
                    .padding(.top, activeJobs.isEmpty ? 0 : 10)

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
    }

    // MARK: - Gating

    private var earnLoadingView: some View {
        VStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var earnLockedView: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.accent)

            VStack(spacing: 10) {
                Text("Earning is locked")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)

                Text("Connect a bank account through Stripe to browse available jobs and get paid for fulfilling them.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, earnHorizontalPadding)

            Button {
                showConnectSetup = true
            } label: {
                Text("Connect with Stripe")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, earnHorizontalPadding)

            Button {
                tabState.selectedTab = 1
            } label: {
                Text("Not earning yet? Switch to Request")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 40)
        .padding(.bottom, AppTheme.tabBarBottomClearance + 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func refreshStripeStatus() {
        guard let uid = authController.userSession?.uid else {
            gateState = .needsConnect
            return
        }

        Firestore.firestore().collection("users").document(uid)
            .getDocument { snapshot, _ in
                let accountId = (snapshot?.data()?["stripeConnectAccountId"] as? String) ?? ""
                DispatchQueue.main.async {
                    if accountId.isEmpty {
                        self.marketController.stopListening()
                        self.gateState = .needsConnect
                    } else {
                        let wasConnected = (self.gateState == .connected)
                        self.gateState = .connected
                        if !wasConnected {
                            self.activityController.fetchActivity(for: uid)
                            self.marketController.fetchOpenOrders()
                        }
                    }
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
                    CompactFulfillerActiveOrderRow(
                        order: order,
                        showsUnreadDot: activityController.unreadTaskOrderIds.contains(order.id ?? "")
                    )
                }
            }
            .padding(.horizontal, earnHorizontalPadding)
            .padding(.bottom, 16)
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
