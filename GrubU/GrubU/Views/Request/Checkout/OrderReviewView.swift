//
//  OrderReviewView.swift
//
//  Fee breakdown + Stripe pay, then writes the open order to Firestore.
//
//  Created by user287016 on 4/18/26.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import StripePaymentSheet

struct OrderReviewView: View {
    @ObservedObject var menuManager: MenuManager
    let restaurantName: String
    let items: [MenuItem]
    let foodCost: Double
    let bounty: Double

    @StateObject private var paymentController = PaymentController()
    @EnvironmentObject var tabState: TabState
    @EnvironmentObject var activityController: ActivityController
    @EnvironmentObject var requestNavigation: RequestNavigationCoordinator

    var grubuFee: Double {
        (bounty * 0.05 * 100).rounded() / 100
    }

    var stripeFee: Double {
        let total = (bounty + grubuFee + 0.30) / (1 - 0.029)
        let fee = total - bounty - grubuFee
        return (fee * 100).rounded() / 100
    }

    var processingFee: Double {
        stripeFee + grubuFee
    }

    var totalCharge: Double {
        bounty + processingFee
    }

    private var displayLines: [BagDisplayLine] {
        BagDisplayLine.lines(from: items)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: "building.2.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.accent)
                    Text(restaurantName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.accent)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 8)

                ProfileSectionHeader(title: "Your order", systemImage: "fork.knife")

                VStack(spacing: 0) {
                    ForEach(Array(displayLines.enumerated()), id: \.1.id) { index, line in
                        orderLineRow(line: line)
                        if index < displayLines.count - 1 {
                            Divider()
                                .background(Color(.separator))
                        }
                    }
                }
                .profileModalCardStyle()

                ProfileSectionHeader(title: "Payment", systemImage: "creditcard.fill")

                VStack(spacing: 0) {
                    reviewSummaryRow(label: "Meal points cost", value: String(format: "$%.2f", foodCost))
                    Divider()
                        .background(Color(.separator))
                    reviewSummaryRow(label: "Bounty (50%)", value: String(format: "$%.2f", bounty))
                    Divider()
                        .background(Color(.separator))
                    reviewSummaryRow(label: "Processing fee", value: String(format: "$%.2f", processingFee))
                    feeSubRow(label: "Stripe fee", value: String(format: "$%.2f", stripeFee))
                    feeSubRow(label: "GrubU fee (5%)", value: String(format: "$%.2f", grubuFee))
                    Divider()
                        .background(Color(.separator))
                    totalRow(value: String(format: "$%.2f", totalCharge))
                }
                .profileModalCardStyle()

                if let error = paymentController.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(AppTheme.accent)
                        .padding(.top, 12)
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, ProfileLayout.horizontalPadding)
            .padding(.top, 18)
            .padding(.bottom, AppTheme.tabBarBottomClearance)
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.pageBackground)
        .navigationTitle("Review order")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                if let paymentSheet = paymentController.paymentSheet {
                    PaymentSheet.PaymentButton(
                        paymentSheet: paymentSheet,
                        onCompletion: handlePaymentResult
                    ) {
                        profilePrimaryButtonLabel("Pay & post request")
                    }
                } else if paymentController.isLoading {
                    ProgressView("Loading payment…")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                } else {
                    Button {
                        Task {
                            await paymentController.preparePaymentSheet(amount: totalCharge)
                        }
                    } label: {
                        profilePrimaryButtonLabel("Retry payment setup")
                    }
                }
            }
            .padding(.horizontal, ProfileLayout.horizontalPadding)
            .padding(.top, 12)
            .padding(.bottom, AppTheme.tabBarBottomClearance)
            .background(AppTheme.pageBackground)
        }
        .onAppear {
            Task {
                await paymentController.preparePaymentSheet(amount: totalCharge)
            }
        }
    }

    private func profilePrimaryButtonLabel(_ title: String) -> some View {
        HStack {
            Spacer()
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(AppTheme.accent)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(Rectangle())
    }

    private func orderLineRow(line: BagDisplayLine) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(line.quantity > 1 ? "\(line.quantity)× \(line.item.name)" : line.item.name)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 16)
            Text(String(format: "$%.2f", line.lineTotal))
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .monospacedDigit()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }

    private func reviewSummaryRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 16)
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .monospacedDigit()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }

    private func feeSubRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Spacer(minLength: 16)
            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .padding(.leading, 12)
    }

    private func totalRow(value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("Total charge")
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer(minLength: 16)
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .monospacedDigit()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }

    func handlePaymentResult(_ result: PaymentSheetResult) {
        switch result {
        case .completed:
            postOrderToFirebase()
        case .canceled:
            break
        case .failed(let error):
            paymentController.errorMessage = error.localizedDescription
        }
    }

    func postOrderToFirebase() {
        let detailStrings = displayLines.map { line in
            line.quantity > 1 ? "\(line.quantity)x \(line.item.name)" : line.item.name
        }
        let newOrder = Order(
            requesterId: Auth.auth().currentUser?.uid ?? "anonymous",
            fulfillerId: nil,
            restaurantName: restaurantName,
            taskLocation: nil,
            orderDetails: detailStrings,
            pickupName: nil,
            estimatedTime: nil,
            foodCost: foodCost,
            bountyAmount: bounty,
            processingFee: processingFee,
            grubhubOrderId: "",
            status: "open",
            proofImageUrl: nil
        )

        let db = Firestore.firestore()
        let docRef = db.collection("orders").document()
        do {
            try docRef.setData(from: newOrder) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error saving order: \(error.localizedDescription)")
                        paymentController.errorMessage = "Couldn’t post your order. Please try again."
                        return
                    }
                    menuManager.bag.removeAll()
                    menuManager.currentRestaurantID = nil
                    if let uid = Auth.auth().currentUser?.uid {
                        activityController.fetchActivity(for: uid)
                    }
                    var posted = newOrder
                    posted.id = docRef.documentID
                    requestNavigation.completeCheckoutNavigateToTracking(posted)
                    tabState.selectedTab = 1
                }
            }
        } catch {
            print("Error encoding order: \(error.localizedDescription)")
            paymentController.errorMessage = error.localizedDescription
        }
    }
}
