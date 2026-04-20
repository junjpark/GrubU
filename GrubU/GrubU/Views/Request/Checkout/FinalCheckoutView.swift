//
//  FinalCheckoutView.swift
//
//  Bag recap + link off to pay / post the order.
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
                ForEach(menuManager.bagDisplayLines) { line in
                    HStack {
                        Text(line.quantity > 1 ? "\(line.quantity)x \(line.item.name)" : line.item.name)
                        Spacer()
                        Text("$\(line.lineTotal, specifier: "%.2f")")
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let id = menuManager.bagDisplayLines[index].id
                        menuManager.removeBagDisplayLine(id: id)
                    }
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
