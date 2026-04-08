//
//  OrderPreviewView.swift
//  
//
//  Created by Julie Baguio on 4/7/26.
//
import SwiftUI
import FirebaseAuth

struct OrderPreviewView: View {
    let order: Order
    @EnvironmentObject var authController: AuthController
    @StateObject private var marketController = MarketController()
    @Environment(\.dismiss) var dismiss
    
    // Track loading state so the user doesn't double-tap
    @State private var isClaiming = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        
                        // 1. THE FINANCIALS
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Payout")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                    .bold()
                                
                                Text("+$\(order.bountyAmount, specifier: "%.2f")")
                                    .font(.largeTitle)
                                    .fontWeight(.heavy) // Added heavy weight for impact
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
                                    .fontWeight(.heavy) // Matched size and weight
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.top, 10)
                        
                        // 2. THE RECEIPT
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "building.2.fill")
                                    .foregroundColor(.gray)
                                Text("Order from: **\(order.restaurantName)**")
                                    .font(.headline)
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
                        
                        // 3. TERMS AND CONDITIONS
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
                
                // 4. ACTION BUTTONS
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
                        
                        Button(action: {
                            processOrderClaim()
                        }) {
                            if isClaiming {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Accept Request")
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
            .navigationTitle("Request Details")
            .navigationBarTitleDisplayMode(.inline)
            .blur(radius: isClaiming ? 2 : 0)
        }
    }
    
    // logic to connect to marketController
    func processOrderClaim() {
        guard let currentUserId = authController.userSession?.uid,
              let orderId = order.id else {
            print("Missing UserID or OrderID")
            return
        }
        
        isClaiming = true
        
        marketController.claimOrder(orderId: orderId, fulfillerId: currentUserId) { success in
            isClaiming = false
            if success {
                dismiss()
            } else {
                // Here you could add an alert to show the user it failed
                print("Failed to claim order in UI")
            }
        }
    }
}
