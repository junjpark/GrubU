//
//  NewRequestView.swift
//  
//
//  Created by Julie Baguio on 4/7/26.
//
import SwiftUI
import FirebaseAuth
import Combine

struct NewRequestView: View {
    @StateObject var menuManager = MenuManager()
    
    var body: some View {
        NavigationView {
            VStack {
                List(menuManager.restaurants) { restaurant in
                    NavigationLink(destination: RestaurantDetailView(restaurant: restaurant, menuManager: menuManager)) {
                        VStack(alignment: .leading) {
                            Text(restaurant.name).font(.headline)
                            Text(restaurant.location).font(.subheadline).foregroundColor(.gray)
                        }
                    }
                }
                
                // THE BAG / CART PREVIEW
                if !menuManager.bag.isEmpty {
                    VStack {
                        HStack {
                            Text("Bag (\(menuManager.bag.count) items)")
                            Spacer()
                            Text("$\(menuManager.totalCost, specifier: "%.2f")")
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        
                        NavigationLink(destination: FinalCheckoutView(menuManager: menuManager)) {
                            Text("View Bag & Post Request")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .navigationTitle("Select Restaurant")
            .onAppear { menuManager.fetchMenus() }
        }
    }
}
