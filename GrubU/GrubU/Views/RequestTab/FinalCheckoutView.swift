//
//  FinalCheckoutView.swift
//  GrubU
//
//  Created by Julie Baguio on 4/7/26.
//
import SwiftUI
import Foundation

struct FinalCheckoutView: View {
    @ObservedObject var menuManager: MenuManager
    @State private var bounty: Double = 5.0
    
    var totalCharge: Double {
        menuManager.totalCost + bounty
    }
    
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
                HStack {
                    Text("Total Charge").bold()
                    Spacer()
                    Text("$\(totalCharge, specifier: "%.2f")").bold()
                }
            }
            
            Section {
                NavigationLink(destination: OrderReviewView(
                    menuManager: menuManager,
                    restaurantName: menuManager.restaurants.first(where: { $0.id == menuManager.currentRestaurantID })?.name ?? "Unknown",
                    items: menuManager.bag,
                    foodCost: menuManager.totalCost,
                    bounty: bounty
                )) {
                    Text("Review Order")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.orange)
                        .bold()
                }
            }
        }
        .navigationTitle("Checkout")
    }
}
