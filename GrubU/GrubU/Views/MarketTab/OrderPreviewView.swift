//
//  OrderPreviewView.swift
//  
//
//  Created by Julie Baguio on 4/7/26.
//
import SwiftUI

struct OrderPreviewView: View {
    let order: Order
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Large Placeholder Image
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 300)
                        .cornerRadius(16)
                    
                    Image(systemName: "takeoutbox.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                // Details Section
                VStack(alignment: .leading, spacing: 12) {
                    Text(order.restaurantName)
                        .font(.largeTitle)
                        .bold()
                    
                    Text("The Order:")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    // NEW: Loop through the array for the details screen
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(order.orderDetails, id: \.self) { item in
                            Text("• \(item)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 10)
                    
                    Divider()
                    
                    // Financial Breakdown
                    HStack {
                        Text("Food Cost (Meal Points)")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(order.foodCost, specifier: "%.2f")")
                            .bold()
                    }
                    
                    HStack {
                        Text("Your Payout (Bounty)")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(order.bountyAmount, specifier: "%.2f")")
                            .bold()
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Claim Button
                Button(action: {
                    claimOrder()
                }) {
                    Text("Claim Order")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // This logic will eventually move to your MarketController
    func claimOrder() {
        print("Claiming order: \(order.id ?? "Unknown ID")")
        // TODO: Update Firestore document status to "claimed" and set fulfillerId
    }
}
