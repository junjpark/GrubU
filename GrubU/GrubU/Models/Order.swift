//
//  Order.swift
//  
//
//  Created by Julie Baguio on 4/7/26.
//
import Foundation
import FirebaseFirestore // Required for the special property wrappers

struct Order: Identifiable, Codable {
    // 0. The Database ID
    // Firebase automatically fills this with the document's unique random ID
    @DocumentID var id: String?
    
    // 1. The People
    var requesterId: String
    var fulfillerId: String
    
    // 2. The Order
    var restaurantName: String
    var orderDetails: String
    
    // 3. The Money
    var foodCost: Double
    var bountyAmount: Double
    
    // 4. The Logistics
    var grubhubOrderId: String
    var status: String
    var proofImageUrl: String
    
    // Firebase automatically injects the server time when this is created
    @ServerTimestamp var createdAt: Date?
}
