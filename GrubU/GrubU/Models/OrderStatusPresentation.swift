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

    // MARK: - Browse (open job, fulfiller only)

    static let earnerAvailableJobTitle = "Available Job"
    static let earnerAvailableJobDetail = """
    This request is open on the board. Accept it when you're ready—you'll use your meal points in Grubhub to place the order as written, then upload a screenshot from Grubhub showing the order is placed or complete. The requester picks up their own food; you do not pick it up for them.
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
                return "Your request is live. Someone on the Earn tab can claim it when they're ready to place it in Grubhub using their meal points."
            case "claimed":
                return "You're matched. Your fulfiller is about to place the Grubhub order—you'll see the next update after they mark it ordered."
            case "ordered":
                return "The fulfiller placed your order in Grubhub. The restaurant is preparing it. When they send proof from Grubhub, you'll pick it up yourself and confirm here."
            case "delivered":
                return "Your fulfiller uploaded Grubhub proof that the order is ready or complete. Pick it up yourself using the pickup details they entered, then confirm below so they're paid."
            case "completed":
                return "You're all set. Rate your fulfiller if you haven't already."
            default:
                return "We're syncing this request. Pull to refresh or check back shortly."
            }
        case .fulfiller:
            switch status {
            case "claimed":
                return "Place this order in Grubhub using your meal points exactly as listed. Add the pickup details the requester will use at the restaurant, confirm you placed it, then mark ordered."
            case "ordered":
                return "When Grubhub shows the order is placed or complete, upload a clear screenshot from the Grubhub app. You are not picking up the food—the requester will. Proof moves this to awaiting confirmation."
            case "delivered":
                return "Proof is sent. The requester needs to confirm they picked up their food before payout finalizes."
            case "completed":
                return "They confirmed pickup. This job is complete and your payout can process per your payout settings."
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
            case "ordered": return Color(red: 0.78, green: 0.58, blue: 0.04)
            case "delivered": return .green
            case "completed": return .purple
            default: return .orange
            }
        case .fulfiller:
            switch status {
            case "claimed": return .red
            case "ordered": return Color(red: 0.78, green: 0.58, blue: 0.04)
            case "delivered": return Color(red: 0.2, green: 0.55, blue: 0.85)
            case "completed": return .purple
            default: return .orange
            }
        }
    }

    private static func fallbackTitle(_ status: String) -> String {
        status
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}
