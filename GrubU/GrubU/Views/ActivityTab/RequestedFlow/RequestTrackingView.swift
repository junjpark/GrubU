import SwiftUI
import FirebaseFirestore

struct RequestTrackingView: View {
    let order: Order
    @Environment(\.dismiss) var dismiss
    private var db = Firestore.firestore()
    
    @State private var isConfirming = false
    
    init(order: Order) {
        self.order = order
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                                HStack(spacing: 10) {
                    let statuses = ["claimed", "ordered", "delivered", "completed"]
                    let currentIndex = statuses.firstIndex(of: order.status) ?? 0
                    
                    ForEach(Array(statuses.enumerated()), id: \.element) { index, step in
                        Rectangle()
                            .frame(height: 8)
                            .foregroundColor(index <= currentIndex ? .orange : .gray.opacity(0.3))
                            .cornerRadius(4)
                    }
                }
                .padding(.top)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Order Status: \(order.status.uppercased())")
                        .font(.caption).bold().foregroundColor(.secondary)
                    Text(statusMessage)
                        .font(.title2).bold()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                if order.status == "completed" {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                            .padding(.top, 20)
                            .padding(.bottom, 5)
                        Text("Order Complete")
                            .font(.title2).bold().foregroundColor(.orange)
                        Text("This request is now finished.")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    
                } else if order.status == "delivered" {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("DELIVERY PROOF")
                            .font(.caption).bold().foregroundColor(.secondary)
                        
                        if let imageUrlString = order.proofImageUrl,
                           !imageUrlString.isEmpty,
                           let validURL = URL(string: imageUrlString) {
                            
                            AsyncImage(url: validURL) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ZStack {
                                    Rectangle().fill(Color.gray.opacity(0.1))
                                    ProgressView()
                                }
                            }
                            .frame(height: 250)
                            .cornerRadius(16)
                            
                        } else {
                            ZStack {
                                Rectangle().fill(Color.gray.opacity(0.1))
                                VStack(spacing: 10) {
                                    Image(systemName: "photo.badge.exclamationmark")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                    Text("No delivery photo provided.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(height: 250)
                            .cornerRadius(16)
                        }
                    }
                    
                    Button(action: confirmReceipt) {
                        HStack {
                            if isConfirming {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 5)
                            }
                            Text(isConfirming ? "Confirming..." : "I have my food")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                    }
                    .disabled(isConfirming)
                    .padding(.top, 10)
                    
                } else if order.status == "ordered" {
                    VStack(spacing: 20) {
                        Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange.opacity(0.7))
                        Text("Your fulfiller is heading to the drop-off location.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange.opacity(0.7))
                        Text("Someone claimed your request! They are currently placing the order.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Track Request")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // --- UI Helpers ---
    var statusMessage: String {
        switch order.status {
        case "claimed": return "Fulfiller is preparing to order."
        case "ordered": return "Food is ordered and on the way."
        case "delivered": return "Your food has arrived at the drop-off."
        case "completed": return "Order complete."
        default: return "Waiting for a fulfiller..."
        }
    }
    
    // --- Logic Helpers ---
    func confirmReceipt() {
        isConfirming = true
        db.collection("orders").document(order.id ?? "").updateData(["status": "completed"]) { error in
            isConfirming = false
            if let error = error {
                print("Error completing order: \(error.localizedDescription)")
            }
        }
    }
}
