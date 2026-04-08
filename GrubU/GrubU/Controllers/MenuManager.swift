//
//  MenuManager.swift
//  GrubU
//
//  Created by Julie Baguio on 4/7/26.
//
import Foundation
import FirebaseAuth
import SwiftUI
import Combine
import FirebaseFirestore

class MenuManager: ObservableObject {
    @Published var restaurants: [Restaurant] = []
    @Published var bag: [MenuItem] = [] // This is your "Cart"
    @Published var currentRestaurantID: String? = nil
    
    private var db = Firestore.firestore()
    
//    func fetchMenus() {
//        db.collection("menus").addSnapshotListener { querySnapshot, error in
//            guard let documents = querySnapshot?.documents else { return }
//            self.restaurants = documents.compactMap { try? $0.data(as: Restaurant.self) }
//        }
//    }
    func fetchMenus() {
        db.collection("menus").addSnapshotListener { querySnapshot, error in
            if let error = error {
                print("Error fetching: \(error.localizedDescription)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                return
            }
            
            self.restaurants = documents.compactMap { doc -> Restaurant? in
                do {
                    return try doc.data(as: Restaurant.self)
                } catch {
                    print("Decoding error for \(doc.documentID): \(error)") // THIS IS KEY
                    return nil
                }
            }
        }
    }
    
    func addToBag(_ item: MenuItem, from restaurantID: String) -> Bool {
        // If bag is not empty and ID doesn't match, block the addition
        if !bag.isEmpty && currentRestaurantID != restaurantID {
            return false
        }
            
        // If it's the first item, set the current restaurant ID
        if bag.isEmpty {
            currentRestaurantID = restaurantID
        }
            
        bag.append(item)
        return true
    }

    func removeFromBag(at offsets: IndexSet) {
        bag.remove(atOffsets: offsets)
            // If the bag becomes empty, reset the restaurant restriction
        if bag.isEmpty {
            currentRestaurantID = nil
        }
    }
    
    var totalCost: Double {
        bag.reduce(0) { $0 + $1.price }
    }
}
