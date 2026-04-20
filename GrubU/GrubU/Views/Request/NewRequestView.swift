//
//  NewRequestView.swift
//
//  Pick a campus restaurant and pile stuff in your bag.
//
//  Created by Julie Baguio on 4/7/26.
//
import SwiftUI

struct NewRequestView: View {
    @ObservedObject var menuManager: MenuManager

    var body: some View {
        VStack(spacing: 0) {
            List(menuManager.restaurants) { restaurant in
                NavigationLink(destination: RestaurantDetailView(restaurant: restaurant, menuManager: menuManager)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(restaurant.name).font(.headline)
                        Text(restaurant.location).font(.subheadline).foregroundColor(.gray)
                    }
                }
            }

            if !menuManager.bag.isEmpty {
                VStack(spacing: 0) {
                    HStack {
                        Text("Bag (\(menuManager.bag.count) items)")
                        Spacer()
                        Text("$\(menuManager.totalCost, specifier: "%.2f")")
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))

                    NavigationLink(destination: FinalCheckoutView(menuManager: menuManager)) {
                        Text("View Bag & Post Request")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
                .background(AppTheme.pageBackground)
                .transition(.move(edge: .bottom))
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { menuManager.fetchMenus() }
    }
}
