//
//  RequestTrackingView.swift
//  
//
//  Created by Julie Baguio on 4/7/26.
//
//
//  RequestTrackingView.swift
//  GrubU
//

import SwiftUI
import FirebaseFirestore

struct RequestTrackingView: View {
    let order: Order
    @Environment(\.dismiss) var dismiss
    
    // Explicit init to match our structural pattern
    init(order: Order) {
        self.order = order
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                
                // 1. PROGRESS BAR
                HStack(spacing: 10) {
                    let statuses = ["claimed", "ordered", "delivered"]
                    let currentIndex = statuses.firstIndex(of: order.status) ?? 0
                    
                    ForEach(Array(statuses.enumerated()), id: \.element) { index, step in
                        Rectangle()
                            .frame(height: 8)
                            .foregroundColor(index <= currentIndex ? .blue : .gray.opacity(0.3))
                            .cornerRadius(4)
                    }
                }
                .padding(.top)

                // 2. CURRENT STATUS HEADER
                VStack(alignment: .leading, spacing: 10) {
                    Text("Order Status: \(order.status.uppercased())")
                        .font(.caption).bold().foregroundColor(.secondary)
                    Text(statusMessage)
                        .font(.title2).bold()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                // 3. DYNAMIC CONTENT
                if order.status == "delivered" {
                    // --- THE DELIVERY PROOF PHOTO ---
                    VStack(alignment: .leading, spacing: 15) {
                        Text("DELIVERY PROOF")
                            .font(.caption).bold().foregroundColor(.secondary)
                        
                        // Using the ultra-safe unwrap we built earlier
                        if let imageUrlString = order.proofImageUrl,
                           !imageUrlString.isEmpty,
                           let validURL = URL(string: imageUrlString) {
                            
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
                            // Fallback if the fulfiller somehow bypassed the photo upload
                            ZStack {
                                Rectangle().fill(Color.gray.opacity(0.1))
                                VStack(spacing: 10) {
                                    Image(systemName: "photo.badge.exclamationmark")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                    Text("No delivery photo provided.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(height: 250)
                            .cornerRadius(16)
                        }
                    }
                    
                    // --- OPTIONAL: CONFIRM RECEIPT BUTTON ---
                    // If you want the requester to "close" the order, you can add an action here later.
                    VStack {
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                            .padding(.top, 20)
                            .padding(.bottom, 5)
                        Text("Enjoy your food!")
                            .font(.headline).foregroundColor(.blue)
                    }
                    
                } else if order.status == "ordered" {
                    // --- WAITING FOR DELIVERY ---
                    VStack(spacing: 20) {
                        Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue.opacity(0.7))
                        Text("Your fulfiller is heading to the drop-off location.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                } else {
                    // --- WAITING FOR ORDER TO BE PLACED ---
                    VStack(spacing: 20) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange.opacity(0.7))
                        Text("Someone claimed your request! They are currently placing the order.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Track Request")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // --- UI Helpers ---
    var statusMessage: String {
        switch order.status {
        case "claimed": return "Fulfiller is preparing to order."
        case "ordered": return "Food is ordered and on the way!"
        case "delivered": return "Your food has arrived!"
        default: return "Waiting for a fulfiller..."
        }
    }
}
