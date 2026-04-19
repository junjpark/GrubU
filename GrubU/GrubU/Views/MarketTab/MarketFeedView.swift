import SwiftUI

struct MarketFeedView: View {
    @EnvironmentObject var authController: AuthController
    @StateObject private var marketController = MarketController()
    
    var body: some View {
        NavigationView {
            Group {
                if marketController.openOrders.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "tray")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No orders available")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("Check back later for new requests.")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.7))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(marketController.openOrders) { order in
                                NavigationLink(destination: OrderPreviewView(order: order)) {
                                    OrderListCell(order: order)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                    }
                }
            }
            .navigationTitle("Market")
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { authController.signOut() }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right").foregroundColor(.red)
                    }
                }
            }
            .onAppear { marketController.fetchOpenOrders() }
            .onDisappear { marketController.stopListening() }
        }
    }
}

struct OrderListCell: View {
    let order: Order
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payout")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Text("+$\(order.bountyAmount, specifier: "%.2f")")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Meal Points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Text("$\(order.foodCost, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(order.orderDetails, id: \.self) { item in
                    Text("• \(item)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
            
            HStack {
                Spacer()
                Text("from \(order.restaurantName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
