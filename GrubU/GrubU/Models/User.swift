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

    var uid: String
    var email: String
    var displayName: String
    var university: String?

    var usdBalance: Double?
    var isBankLinked: Bool?

    var rating: Double?
    var completedOrders: Int?
    var totalRatingsReceived: Int?

    var stripeCustomerId: String?
    var stripeConnectAccountId: String?

    @ServerTimestamp var createdAt: Date?
}
