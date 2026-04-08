import SwiftUI

struct MarketFeedView: View {
    @EnvironmentObject var authController: AuthController
    @StateObject private var marketController = MarketController()
    
    var body: some View {
        NavigationView {
            ScrollView {
                // Switched to a V-Stack for the gig-app card layout
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
            .navigationTitle("Market")
            .background(Color(.systemGroupedBackground)) // Gives a nice gray background so the white cards pop
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Inject Data") { marketController.injectDummyData() }
                        .font(.caption).buttonStyle(.bordered)
                }
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

// MARK: - The New List Cell Design
struct OrderListCell: View {
    let order: Order
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // TOP ROW: The Financials (Highest Priority)
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
            
            // MIDDLE ROW: The Items (Looping through the new array)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(order.orderDetails, id: \.self) { item in
                    Text("• \(item)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
            
            // BOTTOM ROW: The Restaurant
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
        // A subtle shadow mimicking your wireframe border
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
