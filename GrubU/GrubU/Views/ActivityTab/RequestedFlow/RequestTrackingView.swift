//
//  RequestTrackingView.swift
//  
//
//  Created by Julie Baguio on 4/7/26.
//
import SwiftUI

struct RequestTrackingView: View {
    let order: Order
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                
                // 1. DYNAMIC STATUS HEADER
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: statusIcon)
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(statusColor)
                    }
                    
                    Text(statusTitle)
                        .font(.title2)
                        .bold()
                    
                    Text(statusSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 30)

                StatusProgressBar(currentStatus: order.status)
                    .padding(.horizontal)

                // 3. PICKUP DETAILS (The info the fulfiller just submitted)
                // This section only appears once the fulfiller hits "Mark as Ordered"
                if order.status == "ordered" || order.status == "delivered" {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("PICKUP INFORMATION")
                            .font(.caption).bold().foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            DetailRow(icon: "person.fill", label: "Pickup Name", value: order.pickupName ?? "Pending...")
                            DetailRow(icon: "clock.fill", label: "Est. Ready Time", value: order.estimatedTime ?? "Pending...")
                            if let orderNum = order.grubhubOrderId, !orderNum.isEmpty {
                                DetailRow(icon: "number", label: "Order Number", value: orderNum)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.2), lineWidth: 1))
                    }
                    .padding(.horizontal)
                }

                // 4. DELIVERY PROOF (The Photo)
                if order.status == "delivered" {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("DELIVERY PROOF")
                            .font(.caption).bold().foregroundColor(.secondary)
                        
                        // 1. Safely unwrap the string
                        // 2. Ensure it's not empty
                        // 3. Ensure it creates a valid URL
                        if let imageUrlString = order.proofImageUrl,
                           !imageUrlString.isEmpty,
                           let validURL = URL(string: imageUrlString) {
                            
                            // If all checks pass, show the image
                            AsyncImage(url: validURL) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ZStack {
                                    Rectangle().fill(Color.gray.opacity(0.1))
                                    ProgressView()
                                }
                            }
                            .frame(height: 250)
                            .cornerRadius(16)
                            
                        } else {
                            // If any check fails (nil, empty, or invalid), show a placeholder box
                            ZStack {
                                Rectangle().fill(Color.gray.opacity(0.1))
                                Text("No photo provided")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(height: 250)
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal)
                }
                // 5. ORDER SUMMARY (Receipt)
                VStack(alignment: .leading, spacing: 15) {
                    Text("YOUR REQUEST")
                        .font(.caption).bold().foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(order.restaurantName).bold()
                        ForEach(order.orderDetails, id: \.self) { item in
                            Text("• \(item)").font(.subheadline).foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer(minLength: 50)
            }
        }
        .navigationTitle("Order Tracking")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - View Helpers
    
    private var statusColor: Color {
        switch order.status {
        case "delivered": return .green
        case "open": return .gray
        default: return .orange
        }
    }

    private var statusIcon: String {
        switch order.status {
        case "open": return "magnifyingglass"
        case "claimed": return "hand.thumbsup.fill"
        case "ordered": return "cart.fill"
        case "delivered": return "checkmark.seal.fill"
        default: return "ellipsis"
        }
    }

    private var statusTitle: String {
        switch order.status {
        case "open": return "Finding a Runner"
        case "claimed": return "Student Matched!"
        case "ordered": return "Food is Ordered"
        case "delivered": return "Food Delivered!"
        default: return "Processing"
        }
    }

    private var statusSubtitle: String {
        switch order.status {
        case "open": return "Your request is live on the market."
        case "claimed": return "A fulfiller is preparing to place your order."
        case "ordered": return "Your order has been placed. Check the pickup name below!"
        case "delivered": return "Check the photo below for the drop-off location."
        default: return ""
        }
    }
}

// MARK: - Subcomponents

struct StatusProgressBar: View {
    let currentStatus: String
    let steps = ["open", "claimed", "ordered", "delivered"]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(steps, id: \.self) { step in
                Capsule()
                    .frame(height: 6)
                    .foregroundColor(isCompleted(step) ? .orange : Color.gray.opacity(0.2))
            }
        }
    }
    
    func isCompleted(_ step: String) -> Bool {
        let weights = ["open": 0, "claimed": 1, "ordered": 2, "delivered": 3]
        return weights[step]! <= weights[currentStatus]!
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.blue).frame(width: 20)
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).bold()
        }
        .font(.footnote)
    }
}
