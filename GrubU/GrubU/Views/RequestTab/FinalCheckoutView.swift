//
//  FinalCheckoutView.swift
//  GrubU
//
//  Created by Julie Baguio on 4/7/26.
//
import SwiftUI
import Foundation
import FirebaseFirestore
import FirebaseAuth

struct FinalCheckoutView: View {
    @ObservedObject var menuManager: MenuManager
    @State private var bounty: Double = 5.0
    @Environment(\.dismiss) var dismiss // To close the view after posting
    
    var body: some View {
        Form {
            Section(header: Text("Items")) {
                ForEach(menuManager.bag, id: \.self) { item in
                    HStack {
                        Text(item.name)
                        Spacer()
                        Text("$\(item.price, specifier: "%.2f")")
                    }
                }
                .onDelete { offsets in
                    menuManager.removeFromBag(at: offsets)
                }
            }
            
            Section(header: Text("Payment")) {
                HStack {
                    Text("Food Total")
                    Spacer()
                    Text("$\(menuManager.totalCost, specifier: "%.2f")")
                }
                Stepper("Bounty: $\(bounty, specifier: "%.0f")", value: $bounty, in: 2...20)
            }
            
            Button("Confirm & Post Request") {
                postOrderToFirebase()
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(.orange)
            .bold()
        }
        .navigationTitle("Checkout")
    }
    
    func postOrderToFirebase() {
        // 1. Get the restaurant name from the first item in the bag (since they are all the same)
        // We use a fallback "Unknown Restaurant" just in case the bag is empty
        let restaurantName = menuManager.restaurants.first(where: { $0.id == menuManager.currentRestaurantID })?.name ?? "Unknown Restaurant"
        
        // 2. Initialize the Order struct
        
        let newOrder = Order(
            
            requesterId: Auth.auth().currentUser?.uid ?? "anonymous",
            fulfillerId: "", // Empty because no one has picked it up yet
            restaurantName: restaurantName,
            orderDetails: menuManager.bag.map { $0.name }, // Converts [MenuItem] to [String]
            pickupName: nil,       // To be filled later
            estimatedTime: nil,    // To be filled later
            foodCost: menuManager.totalCost,
            bountyAmount: bounty,
            grubhubOrderId: "",    // To be filled by user or system later
            status: "pending",     // Initial status
            proofImageUrl: ""      // No image yet
        )
        
        // 3. Save to Firestore
        let db = Firestore.firestore()
        do {
            // This automatically uses Codable to map your struct to Firestore fields
            try db.collection("orders").addDocument(from: newOrder) { error in
                if let error = error {
                    print("Error saving order: \(error.localizedDescription)")
                } else {
                    print("Order successfully posted!")
                    
                    // 4. Clean up the bag and manager state
                    menuManager.bag.removeAll()
                    menuManager.currentRestaurantID = nil
                    
                    // 5. Return to the previous screen
                    dismiss()
                }
            }
        } catch {
            print("Error encoding order: \(error.localizedDescription)")
        }
    }
}
