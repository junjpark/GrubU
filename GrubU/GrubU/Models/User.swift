//
//  User.swift
//  
//
//  Created by Julie Baguio on 4/7/26.
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?

    // Core Identity
    var uid: String
    var email: String
    var displayName: String
    var university: String?

    // Financials
    var usdBalance: Double?
    var isBankLinked: Bool?

    // Platform Stats
    var rating: Double?
    var completedOrders: Int?
    var totalRatingsReceived: Int?

    // Stripe
    var stripeCustomerId: String?
    var stripeConnectAccountId: String?

    @ServerTimestamp var createdAt: Date?
}
