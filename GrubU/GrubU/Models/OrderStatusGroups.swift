//
//  OrderStatusGroups.swift
//
//  Little helpers: is this order "active" for fulfiller vs requester.
//
//  Created by Julie Baguio on 4/7/26.
//

import Foundation

enum OrderStatusGroups {
    static func isActiveFulfiller(_ status: String) -> Bool {
        ["claimed", "ordered", "delivered", IssueReportController.issueStatus].contains(status)
    }

    static func isActiveRequester(_ status: String) -> Bool {
        status != "completed"
    }
}
