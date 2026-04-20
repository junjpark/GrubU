//
//  Order.swift
//
//  One Firestore order — people, money, status, stripe bits.
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
    /// When set, shown as the task’s meeting / pickup location (campus building, dorm, etc.).
    var taskLocation: String?
    var orderDetails: [String]
    var pickupName: String?
    var estimatedTime: String?
    var foodCost: Double
    var bountyAmount: Double
    var processingFee: Double?
    var grubhubOrderId: String?
    var status: String
    var proofImageUrl: String?
    var stripePaymentIntentId: String?
    var fulfillerRating: Double?
    @ServerTimestamp var createdAt: Date?
}

extension Order: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(requesterId)
        hasher.combine(restaurantName)
        hasher.combine(status)
        hasher.combine(foodCost)
        hasher.combine(bountyAmount)
    }

    static func == (lhs: Order, rhs: Order) -> Bool {
        lhs.id == rhs.id
            && lhs.requesterId == rhs.requesterId
            && lhs.restaurantName == rhs.restaurantName
            && lhs.status == rhs.status
            && lhs.foodCost == rhs.foodCost
            && lhs.bountyAmount == rhs.bountyAmount
    }
}
