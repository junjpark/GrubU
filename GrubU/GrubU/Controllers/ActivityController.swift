//
//  ActivityController.swift
//  
//
//  Created by Julie Baguio on 4/7/26.
//
import Foundation
import FirebaseFirestore
import Combine
import SwiftUI

class ActivityController: ObservableObject {
    @Published var requestedOrders: [Order] = []
    @Published var fulfillingTasks: [Order] = []
    
    private var db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []

    func fetchActivity(for uid: String) {
        guard listeners.isEmpty else { return }

        let reqListener = db.collection("orders")
            .whereField("requesterId", isEqualTo: uid)
            .addSnapshotListener { snapshot, _ in
                self.requestedOrders = snapshot?.documents.compactMap { try? $0.data(as: Order.self) } ?? []
            }
        
        //fetch orders that user is fulfilling
        let fulListener = db.collection("orders")
            .whereField("fulfillerId", isEqualTo: uid)
            .addSnapshotListener { snapshot, _ in
                self.fulfillingTasks = snapshot?.documents.compactMap { try? $0.data(as: Order.self) } ?? []
            }
            
        listeners.append(contentsOf: [reqListener, fulListener])
    }
}
