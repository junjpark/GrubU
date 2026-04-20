//
//  OrderPreviewView.swift
//
//  One open order: details + accept job (Stripe Connect gate).
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
    @StateObject private var marketController = MarketController()
    @Environment(\.dismiss) var dismiss

    @State private var isClaiming = false
    @State private var showConnectSetup = false
    @State private var showOrderTaken = false
    @State private var stripeConnectId: String?

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {

                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Payout")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                    .bold()
                                Text("+$\(order.bountyAmount, specifier: "%.2f")")
                                    .font(.largeTitle)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.green)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Meal Points")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                    .bold()
                                Text("-$\(order.foodCost, specifier: "%.2f")")
                                    .font(.largeTitle)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.top, 10)

                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "checklist")
                                        .foregroundColor(.gray)
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
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Terms & Conditions:")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.secondary)
                            Text("By accepting this request, you commit to placing this order using your funds and uploading proof of delivery. Unfulfilled accepted requests negatively impact your rating and may result in account suspension.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }

                VStack {
                    Divider()
                    HStack(spacing: 16) {
                        Button(action: { dismiss() }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(UIColor.systemGray5))
                                .cornerRadius(14)
                        }
                        .disabled(isClaiming)

                        Button(action: { handleAcceptTapped() }) {
                            if isClaiming {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Accept Job")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.orange)
                                    .cornerRadius(14)
                            }
                        }
                        .disabled(isClaiming)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Color(UIColor.systemBackground))
            }
            .navigationTitle("Job details")
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
                tabState.selectedTab = 0
            } else {
                print("Failed to claim order in UI")
            }
        }
    }
}
