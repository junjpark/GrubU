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
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Image(systemName: "building.2.fill")
                        .foregroundStyle(AppTheme.accent)
                    Text(restaurantName)
                        .font(.title2.bold())
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("YOUR ORDER")
                        .font(.caption).bold().foregroundColor(.secondary)
                    ForEach(displayLines) { line in
                        HStack {
                            Text(line.quantity > 1 ? "\(line.quantity)x \(line.item.name)" : line.item.name)
                            Spacer()
                            Text("$\(line.lineTotal, specifier: "%.2f")")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .profileModalCardStyle()

                VStack(spacing: 12) {
                    HStack {
                        Text("Meal Points Cost")
                        Spacer()
                        Text("$\(foodCost, specifier: "%.2f")")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Bounty (50%)")
                        Spacer()
                        Text("$\(bounty, specifier: "%.2f")")
                    }

                    HStack {
                        Text("Processing Fee")
                        Spacer()
                        Text("$\(processingFee, specifier: "%.2f")")
                    }

                    HStack {
                        HStack(spacing: 4) {
                            Text("├")
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("Stripe Fee")
                        }
                        Spacer()
                        Text("$\(stripeFee, specifier: "%.2f")")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 16)

                    HStack {
                        HStack(spacing: 4) {
                            Text("└")
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("GrubU Fee (5%)")
                        }
                        Spacer()
                        Text("$\(grubuFee, specifier: "%.2f")")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 16)

                    Divider()
                        .background(Color(.separator).opacity(0.55))

                    HStack {
                        Text("Total").bold()
                        Spacer()
                        Text("$\(totalCharge, specifier: "%.2f")").bold()
                    }
                }
                .padding()
                .profileModalCardStyle()

                if let error = paymentController.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.pageBackground)
        .navigationTitle("Review Order")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            VStack {
                if let paymentSheet = paymentController.paymentSheet {
                    PaymentSheet.PaymentButton(
                        paymentSheet: paymentSheet,
                        onCompletion: handlePaymentResult
                    ) {
                        Text("Pay & Post Request")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                } else if paymentController.isLoading {
                    ProgressView("Loading payment...")
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Button {
                        Task {
                            await paymentController.preparePaymentSheet(amount: totalCharge)
                        }
                    } label: {
                        Text("Retry Payment Setup")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
            .padding()
            .padding(.bottom, AppTheme.tabBarBottomClearance)
            .background(AppTheme.pageBackground)
        }
        .onAppear {
            Task {
                await paymentController.preparePaymentSheet(amount: totalCharge)
            }
        }
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
