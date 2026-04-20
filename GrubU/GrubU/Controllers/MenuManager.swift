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

struct BagDisplayLine: Identifiable, Hashable {
    let id: String
    let item: MenuItem
    let quantity: Int

    var lineTotal: Double { Double(quantity) * item.price }

    static func lines(from items: [MenuItem]) -> [BagDisplayLine] {
        var lines: [BagDisplayLine] = []
        for item in items {
            if let i = lines.firstIndex(where: { $0.item.name == item.name && $0.item.price == item.price }) {
                let prev = lines[i]
                lines[i] = BagDisplayLine(id: prev.id, item: prev.item, quantity: prev.quantity + 1)
            } else {
                let id = "\(item.name)#\(item.price)"
                lines.append(BagDisplayLine(id: id, item: item, quantity: 1))
            }
        }
        return lines
    }
}

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

    var bagDisplayLines: [BagDisplayLine] {
        BagDisplayLine.lines(from: bag)
    }

    func removeBagDisplayLine(id: String) {
        bag.removeAll { "\($0.name)#\($0.price)" == id }
        if bag.isEmpty {
            currentRestaurantID = nil
        }
    }
}
