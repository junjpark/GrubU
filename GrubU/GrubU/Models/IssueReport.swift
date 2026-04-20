//
//  IssueReport.swift
//
//  One user-submitted support ticket tied to an order.
//
//  Created by Julie Baguio on 4/20/26.
//

import Foundation
import FirebaseFirestore

struct IssueReport: Identifiable, Codable {
    @DocumentID var id: String?
    var orderId: String
    var reporterUid: String
    /// "requester" or "fulfiller"
    var reporterRole: String
    var reporterEmail: String?
    var description: String
    /// The order's status at the moment the issue was filed.
    var orderStatusAtReport: String
    /// "open" | "in_review" | "resolved"
    var status: String
    @ServerTimestamp var createdAt: Date?
}
