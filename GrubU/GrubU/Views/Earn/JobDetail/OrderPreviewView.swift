//
//  OrderPreviewView.swift
//
//  One open order: details + accept order (Stripe Connect gate).
//
//  Created by Julie Baguio on 4/7/26.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct OrderPreviewView: View {
    let order: Order
    @EnvironmentObject var authController: AuthController
    @EnvironmentObject var tabState: TabState
    @EnvironmentObject var activityController: ActivityController
    @Environment(\.earnPostClaimNavigation) private var earnPostClaimNavigation
    @StateObject private var marketController = MarketController()
    @Environment(\.dismiss) var dismiss

    @State private var isClaiming = false
    @State private var showConnectSetup = false
    @State private var showOrderTaken = false
    @State private var stripeConnectId: String?

    var body: some View {
        ZStack {
            AppTheme.pageBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(OrderStatusPresentation.earnerAvailableOrderTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.accent)
                            Text(OrderStatusPresentation.earnerAvailableOrderDetail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .profileModalCardStyle()

                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Meal Points")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                    .bold()
                                Text("$\(order.foodCost, specifier: "%.2f")")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Payout")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                    .bold()
                                Text(String(format: "+$%.2f", order.bountyAmount))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                        .padding(20)
                        .profileModalCardStyle()

                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "checklist")
                                        .foregroundStyle(.secondary)
                                    Text(order.restaurantName)
                                        .font(.headline)
                                }
                                if let loc = order.taskLocation, !loc.isEmpty {
                                    Label(loc, systemImage: "mappin.and.ellipse")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Divider()
                                .background(Color(.separator).opacity(0.55))
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(order.orderDetails, id: \.self) { item in
                                    HStack(alignment: .top) {
                                        Text("•").bold().foregroundColor(.secondary)
                                        Text(item)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                        .padding()
                        .profileModalCardStyle()

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Terms & Conditions:")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.secondary)
                            Text("By accepting this request, you commit to placing it in Grubhub with your meal points and uploading proof from Grubhub when the order is placed or complete. The requester picks up their own food. Unfulfilled orders may affect your rating and account.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                        .padding()
                        .profileModalCardStyle()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .scrollContentBackground(.hidden)
                .background(AppTheme.pageBackground)

                VStack {
                    Divider()
                        .background(Color(.separator).opacity(0.55))
                    HStack(spacing: 16) {
                        Button(action: { dismiss() }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .profileModalCardStyle()
                        }
                        .disabled(isClaiming)

                        Button(action: { handleAcceptTapped() }) {
                            if isClaiming {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Accept Order")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(AppTheme.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                        .disabled(isClaiming)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 16 + AppTheme.tabBarBottomClearance)
                }
                .background(AppTheme.pageBackground)
            }
            .navigationTitle("Order details")
            .navigationBarTitleDisplayMode(.inline)
            .blur(radius: isClaiming ? 2 : 0)
            .onAppear { fetchStripeStatus() }
            .sheet(isPresented: $showConnectSetup, onDismiss: {
                fetchStripeStatus()
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
            .alert("Order Unavailable", isPresented: $showOrderTaken) {
                Button("OK") { dismiss() }
            } message: {
                Text("This order has already been accepted by another fulfiller.")
            }
        }
    }

    func handleAcceptTapped() {
        if stripeConnectId == nil || stripeConnectId?.isEmpty == true {
            showConnectSetup = true
            return
        }

        isClaiming = true
        guard let orderId = order.id else {
            isClaiming = false
            return
        }

        Firestore.firestore().collection("orders").document(orderId).getDocument { snapshot, _ in
            guard let data = snapshot?.data(), data["status"] as? String == "open" else {
                isClaiming = false
                showOrderTaken = true
                return
            }
            processOrderClaim()
        }
    }

    func fetchStripeStatus() {
        guard let uid = authController.userSession?.uid else { return }
        Firestore.firestore().collection("users").document(uid)
            .getDocument { snapshot, _ in
                if let data = snapshot?.data() {
                    self.stripeConnectId = data["stripeConnectAccountId"] as? String
                }
            }
    }

    func processOrderClaim() {
        guard let currentUserId = authController.userSession?.uid,
              let orderId = order.id else {
            isClaiming = false
            return
        }

        marketController.claimOrder(orderId: orderId, fulfillerId: currentUserId) { success in
            isClaiming = false
            if success {
                var claimed = order
                claimed.status = "claimed"
                claimed.fulfillerId = currentUserId
                if let uid = authController.userSession?.uid {
                    activityController.fetchActivity(for: uid)
                }
                tabState.selectedTab = 0
                dismiss()
                DispatchQueue.main.async {
                    earnPostClaimNavigation?.postClaimOrder = claimed
                }
            } else {
                print("Failed to claim order in UI")
            }
        }
    }
}
