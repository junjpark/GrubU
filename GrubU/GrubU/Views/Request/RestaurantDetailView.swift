//
//  RestaurantDetailView.swift
//
//  One restaurant’s menu; plus buttons chuck items in the bag.
//
//  Created by Julie Baguio on 4/7/26.
//
import SwiftUI
import Foundation

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    @ObservedObject var menuManager: MenuManager
    
    @State private var showRestaurantAlert = false
    // 1. Add state to track the notification
    @State private var showToast = false
    @State private var addedItemName = ""
    
    var body: some View {
        ZStack { // 2. Wrap everything in a ZStack
            List(restaurant.items, id: \.name) { item in
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.name).font(.headline)
                        Text(item.description).font(.caption).foregroundColor(.gray)
                        Text("$\(item.price, specifier: "%.2f")").bold()
                    }
                    Spacer()
                    Button(action: {
                        // We pass 'item' AND the current 'restaurant.id'
                        // We use ?? "" because restaurant.id is an optional String
                        let success = menuManager.addToBag(item, from: restaurant.id ?? "")
                        
                        if success {
                            triggerToast(for: item.name)
                        } else {
                            showRestaurantAlert = true
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle(restaurant.name)
            .alert(isPresented: $showRestaurantAlert) {
                            Alert(
                                title: Text("Different Restaurant"),
                                message: Text("You can only order from one restaurant at a time. Please clear your bag to switch."),
                                dismissButton: .default(Text("OK"))
                            )
            }

            // 4. The Notification Overlay
            if showToast {
                VStack {
                    Spacer()
                    Text("Added \(addedItemName) to bag")
                        .font(.subheadline)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 50)
                }
                .animation(.spring(), value: showToast)
            }
        }
    }
    
    // 5. Helper function to show and hide the toast
    func triggerToast(for name: String) {
        addedItemName = name
        showToast = true
        
        // Hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showToast = false
            }
        }
    }
}
