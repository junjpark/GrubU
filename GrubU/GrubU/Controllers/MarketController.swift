//
//  MarketController.swift
//  
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
            // Listen to the "orders" collection for anything marked "open"
            listenerRegistration = db.collection("orders")
                .whereField("status", isEqualTo: "open")
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let documents = snapshot?.documents else {
                        print("Error fetching orders: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    // convert the documents to Swift Orders
                    let fetchedOrders = documents.compactMap { document in
                        try? document.data(as: Order.self)
                    }
                    
                    // sort them locally in Swift
                    // If the timestamp is missing (during the split-second upload), it defaults to right now.
                    let sortedOrders = fetchedOrders.sorted {
                        ($0.createdAt ?? Date()) > ($1.createdAt ?? Date())
                    }
                    
                    // update the UI safely on the main thread
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
    
    // TEMPORARY: Run this once to populate the database
    func injectDummyData() {
            guard let currentUid = Auth.auth().currentUser?.uid else { return }
            
            let order1 = Order(
                requesterId: currentUid,
                fulfillerId: "",
                restaurantName: "Corner 17",
                // Notice the array format here:
                orderDetails: ["1x Sichuan Spicy Fish Fillet (Mild)", "1x Side of White Rice", "1x Boba Milk Tea"],
                foodCost: 24.50,
                bountyAmount: 6.00,
                grubhubOrderId: "",
                status: "open",
                proofImageUrl: ""
            )
            
            let order2 = Order(
                requesterId: currentUid,
                fulfillerId: "",
                restaurantName: "Papa Johns",
                orderDetails: ["1x Large Pepperoni Pizza", "1x Garlic Sauce"],
                foodCost: 14.00,
                bountyAmount: 4.50,
                grubhubOrderId: "",
                status: "open",
                proofImageUrl: ""
            )
            
            do {
                let db = Firestore.firestore()
                try db.collection("orders").document().setData(from: order1)
                try db.collection("orders").document().setData(from: order2)
                print("Dummy data successfully injected!")
            } catch {
                print("Failed to inject data: \(error.localizedDescription)")
            }
        }
}
