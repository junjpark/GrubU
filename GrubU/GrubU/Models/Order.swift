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
    var fulfillerId: String?
    var restaurantName: String
    var orderDetails: [String]
    var pickupName: String?
    var estimatedTime: String?
    var foodCost: Double
    var bountyAmount: Double
    var grubhubOrderId: String?
    var status: String
    var proofImageUrl: String?
    var stripePaymentIntentId: String?
    @ServerTimestamp var createdAt: Date?
}
