//
//  OrderReviewView.swift
//  GrubU
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
    @Environment(\.dismiss) var dismiss

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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(.orange)
                    Text(restaurantName)
                        .font(.title2.bold())
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("YOUR ORDER")
                        .font(.caption).bold().foregroundColor(.secondary)
                    ForEach(items, id: \.name) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            Text("$\(item.price, specifier: "%.2f")")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)

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

                    HStack {
                        Text("Total").bold()
                        Spacer()
                        Text("$\(totalCharge, specifier: "%.2f")").bold()
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)

                if let error = paymentController.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding()
        }
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
                            .background(Color.orange)
                            .cornerRadius(14)
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
                            .background(Color.orange)
                            .cornerRadius(14)
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
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
        let newOrder = Order(
            requesterId: Auth.auth().currentUser?.uid ?? "anonymous",
            fulfillerId: "",
            restaurantName: restaurantName,
            orderDetails: items.map { $0.name },
            pickupName: nil,
            estimatedTime: nil,
            foodCost: foodCost,
            bountyAmount: bounty,
            processingFee: processingFee,
            grubhubOrderId: "",
            status: "open",
            proofImageUrl: ""
        )

        let db = Firestore.firestore()
        do {
            try db.collection("orders").addDocument(from: newOrder) { error in
                if let error = error {
                    print("Error saving order: \(error.localizedDescription)")
                } else {
                    print("Order successfully posted!")
                    menuManager.bag.removeAll()
                    menuManager.currentRestaurantID = nil
                    tabState.activitySegment = 0
                    tabState.selectedTab = 2
                }
            }
        } catch {
            print("Error encoding order: \(error.localizedDescription)")
        }
    }
}
