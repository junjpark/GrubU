//
//  MarketController.swift
//
//  Open orders feed + “claim this order” Firestore update.
//
//  Created by Julie Baguio on 4/7/26.
//
import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class MarketController: ObservableObject {
    @Published var openOrders: [Order] = []
    private var db = Firestore.firestore()
    
    // We store the listener so we can turn it off if needed
    private var listenerRegistration: ListenerRegistration?
    
    func fetchOpenOrders() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }

        listenerRegistration = db.collection("orders")
            .whereField("status", isEqualTo: "open")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let fetchedOrders = documents.compactMap { document -> Order? in
                    if let order = try? document.data(as: Order.self) {
                        if order.requesterId != currentUserID {
                            return order
                        }
                    }
                    return nil
                }
                
                let sortedOrders = fetchedOrders.sorted {
                    ($0.createdAt ?? Date()) > ($1.createdAt ?? Date())
                }
                
                DispatchQueue.main.async {
                    self?.openOrders = sortedOrders
                }
            }
    }
    
    func stopListening() {
        listenerRegistration?.remove()
    }
    
    func claimOrder(orderId: String, fulfillerId: String, completion: @escaping (Bool) -> Void) {
        let orderRef = db.collection("orders").document(orderId)
        
        // We use a dictionary update to only change the specific fields we need
        orderRef.updateData([
            "status": "claimed",
            "fulfillerId": fulfillerId
        ]) { error in
            if let error = error {
                print("Error claiming order: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Successfully claimed order!")
                completion(true)
            }
        }
    }

    /// Requester-side cancel. Only safe while the order is still `open` (no fulfiller yet).
    /// Uses a Firestore transaction so we don't race with a fulfiller claiming at the same time.
    /// TODO: trigger a Stripe refund via a cloud function for production-grade handling.
    func cancelOpenRequest(orderId: String, completion: @escaping (Bool) -> Void) {
        let orderRef = db.collection("orders").document(orderId)
        db.runTransaction({ transaction, errorPointer -> Any? in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(orderRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            guard let status = snapshot.data()?["status"] as? String, status == "open" else {
                let stateError = NSError(
                    domain: "MarketController",
                    code: 409,
                    userInfo: [NSLocalizedDescriptionKey: "Request is no longer open and cannot be canceled."]
                )
                errorPointer?.pointee = stateError
                return nil
            }
            transaction.deleteDocument(orderRef)
            return nil
        }) { _, error in
            if let error = error {
                print("Error canceling request: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    /// Fulfiller-side release. Only safe while still `claimed` (haven't placed the Grubhub order).
    /// Re-opens the request for someone else to accept.
    func releaseClaimedOrder(orderId: String, fulfillerId: String, completion: @escaping (Bool) -> Void) {
        let orderRef = db.collection("orders").document(orderId)
        db.runTransaction({ transaction, errorPointer -> Any? in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(orderRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            let data = snapshot.data() ?? [:]
            let status = data["status"] as? String ?? ""
            let currentFulfiller = data["fulfillerId"] as? String ?? ""
            guard status == "claimed", currentFulfiller == fulfillerId else {
                let stateError = NSError(
                    domain: "MarketController",
                    code: 409,
                    userInfo: [NSLocalizedDescriptionKey: "This order can no longer be released."]
                )
                errorPointer?.pointee = stateError
                return nil
            }
            transaction.updateData([
                "status": "open",
                "fulfillerId": FieldValue.delete()
            ], forDocument: orderRef)
            return nil
        }) { _, error in
            if let error = error {
                print("Error releasing order: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
}
