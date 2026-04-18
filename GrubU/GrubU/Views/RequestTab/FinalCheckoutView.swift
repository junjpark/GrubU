//
//  FinalCheckoutView.swift
//  GrubU
//
//  Created by Julie Baguio on 4/7/26.
//
import SwiftUI

struct FinalCheckoutView: View {
    @ObservedObject var menuManager: MenuManager

    var bounty: Double {
        (menuManager.totalCost * 0.50 * 100).rounded() / 100
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

            Section(header: Text("Cost Breakdown")) {
                HStack {
                    Text("Meal Points Cost")
                    Spacer()
                    Text("$\(menuManager.totalCost, specifier: "%.2f")")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Bounty (50%)")
                    Spacer()
                    Text("$\(bounty, specifier: "%.2f")")
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
