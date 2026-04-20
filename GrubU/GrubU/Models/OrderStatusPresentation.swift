//
//  OrderStatusPresentation.swift
//
//  Human-readable order phases for requesters vs fulfillers (Firestore values stay unchanged).
//  Fulfillers place the Grubhub order with meal points and upload in-app proof; requesters pick up themselves.
//
//  Created by Julie Baguio on 4/20/26.
//

import SwiftUI

enum OrderStatusRole {
    case requester
    case fulfiller
}

enum OrderStatusPresentation {
    /// Requester progress strip: posted → … → complete.
    static let requesterProgressPipeline = ["open", "claimed", "ordered", "delivered", "completed"]
    /// Fulfiller progress strip (after claim only).
    static let fulfillerProgressPipeline = ["claimed", "ordered", "delivered", "completed"]

    static func progressIndex(pipeline: [String], status: String) -> Int {
        pipeline.firstIndex(of: status) ?? 0
    }

    // MARK: - Browse (open order, fulfiller only)

    static let earnerAvailableOrderTitle = "Available Order"
    static let earnerAvailableOrderDetail = """
    This request is open. Accept it when you're ready to place the order in Grubhub using your meal points.
    """

    // MARK: - Short labels (hub rows, list rows, tracking headline)

    static func shortLabel(status: String, role: OrderStatusRole) -> String {
        switch role {
        case .requester:
            switch status {
            case "open": return "Posted"
            case "claimed": return "Matched"
            case "ordered": return "Being Prepared"
            case "delivered": return "Ready for Pick Up"
            case "completed": return "Complete"
            default:
                return fallbackTitle(status)
            }
        case .fulfiller:
            switch status {
            case "claimed": return "Place the Order"
            case "ordered": return "Update When Complete"
            case "delivered": return "Awaiting Confirmation"
            case "completed": return "Complete"
            default:
                return fallbackTitle(status)
            }
        }
    }

    // MARK: - Detail copy (tracking screens)

    static func detailMessage(status: String, role: OrderStatusRole) -> String {
        switch role {
        case .requester:
            switch status {
            case "open":
                return "Your request is live. Someone will claim your order soon."
            case "claimed":
                return "You're matched! Look out for an update when your Grubber places the order."
            case "ordered":
                return "Your Grubber placed the order! Look out for an update when the order is ready for pickup."
            case "delivered":
                return "Your order is ready for pickup! Confirm all food items are present and correct, then mark your order as complete."
            case "completed":
                return "You're all set. Rate your Grubber!"
            default:
                return "We're syncing this request. Pull to refresh or check back shortly."
            }
        case .fulfiller:
            switch status {
            case "claimed":
                return "Place the order in Grubhub and input pickup details."
            case "ordered":
                return "Upload a screenshot of the order when it is ready for pickup!"
            case "delivered":
                return "We'll take it from here! Once your Grubee confirms pickup, your payout will be sent to your account."
            case "completed":
                return "Your Grubee confirmed pickup! Your payout will be sent to your account shortly."
            default:
                return "We're syncing this task. Pull to refresh or check back shortly."
            }
        }
    }

    // MARK: - Row / chip tint (matches existing hub styling)

    static func accentColor(status: String, role: OrderStatusRole) -> Color {
        switch role {
        case .requester:
            switch status {
            case "open": return AppTheme.accent
            case "claimed": return .blue
            case "ordered": return AppTheme.accent
            case "delivered": return .green
            case "completed": return .purple
            default: return AppTheme.accent
            }
        case .fulfiller:
            switch status {
            case "claimed": return AppTheme.accent
            case "ordered": return AppTheme.accent
            case "delivered": return Color(red: 0.2, green: 0.55, blue: 0.85)
            case "completed": return .purple
            default: return AppTheme.accent
            }
        }
    }

    private static func fallbackTitle(_ status: String) -> String {
        status
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}
