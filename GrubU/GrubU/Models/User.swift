//
//  User.swift
//  
//
//  Created by Julie Baguio on 4/7/26.
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    // 0. The Database ID (Automatically maps to the document ID in Firestore)
    @DocumentID var id: String?
    
    // 1. Core Identity
    var uid: String
    var email: String
    var displayName: String
    var university: String
    
    // 2. The Financials
    var usdBalance: Double
    var isBankLinked: Bool
    
    // 3. Platform Stats
    var rating: Double
    var completedOrders: Int
    
    // 4. Stripe
    var stripeCustomerId: String?       // for charging requesters
    var stripeConnectAccountId: String?  // for paying out fulfillers
    
    // Automatically grabs the exact time the account was created
    @ServerTimestamp var createdAt: Date?
}
