//
//  IssueReportController.swift
//
//  Writes an issue report to Firestore and pauses the underlying order
//  so it can't advance or pay out while the support team investigates.
//
//  Created by Julie Baguio on 4/20/26.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

final class IssueReportController: ObservableObject {
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    /// Orders with this status are hidden from forward progress UI;
    /// admins review the matching `issueReports` doc and manually resolve.
    static let issueStatus = "issue_reported"

    private let db = Firestore.firestore()

    func submitReport(
        order: Order,
        role: OrderStatusRole,
        description: String,
        completion: @escaping (Bool) -> Void
    ) {
        guard let orderId = order.id, !orderId.isEmpty else {
            setError("This order is missing an ID; please try again.")
            completion(false)
            return
        }
        guard let user = Auth.auth().currentUser else {
            setError("You need to be signed in to report an issue.")
            completion(false)
            return
        }
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 10 else {
            setError("Please describe the issue in a little more detail (at least 10 characters).")
            completion(false)
            return
        }

        DispatchQueue.main.async {
            self.isSubmitting = true
            self.errorMessage = nil
        }

        let roleString = (role == .requester) ? "requester" : "fulfiller"
        let reportRef = db.collection("issueReports").document()
        let orderRef = db.collection("orders").document(orderId)

        let reportPayload: [String: Any] = [
            "orderId": orderId,
            "reporterUid": user.uid,
            "reporterRole": roleString,
            "reporterEmail": user.email ?? "",
            "description": trimmed,
            "orderStatusAtReport": order.status,
            "status": "open",
            "createdAt": FieldValue.serverTimestamp()
        ]

        var orderUpdate: [String: Any] = [
            "issueReportId": reportRef.documentID,
            "lastIssueReportedAt": FieldValue.serverTimestamp()
        ]
        // Completed orders stay completed (payout already happened);
        // everything else gets frozen in the "issue reported" state.
        if order.status != "completed" {
            orderUpdate["status"] = Self.issueStatus
        }

        let batch = db.batch()
        batch.setData(reportPayload, forDocument: reportRef)
        batch.updateData(orderUpdate, forDocument: orderRef)

        batch.commit { [weak self] error in
            DispatchQueue.main.async {
                self?.isSubmitting = false
                if let error = error {
                    self?.errorMessage = "Couldn't submit report: \(error.localizedDescription)"
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }

    private func setError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.isSubmitting = false
        }
    }
}
