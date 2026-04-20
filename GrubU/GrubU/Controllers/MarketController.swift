//
//  MarketController.swift
//
//  Open orders feed + “claim this job” Firestore update.
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
}
