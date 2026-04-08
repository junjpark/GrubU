//
//  Order.swift
//  
//
//  Created by Julie Baguio on 4/7/26.
//
import Foundation
import FirebaseFirestore

struct Order: Identifiable, Codable {
    @DocumentID var id: String?
    var requesterId: String
    var fulfillerId: String
    var restaurantName: String
    
    // CHANGED: Now an array of items for clean bullet points
    var orderDetails: [String]
    
    var foodCost: Double
    var bountyAmount: Double
    var grubhubOrderId: String
    var status: String
    var proofImageUrl: String
    @ServerTimestamp var createdAt: Date?
}
