import SwiftUI
import FirebaseFirestore

struct RequestTrackingView: View {
    let initialOrder: Order
    @Environment(\.dismiss) var dismiss
    private var db = Firestore.firestore()

    @State private var liveOrder: Order?
    @State private var isConfirming = false
    @State private var selectedRating: Int = 5
    @State private var ratingSubmitted = false

    init(order: Order) {
        self.initialOrder = order
    }

    private var order: Order {
        liveOrder ?? initialOrder
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                HStack(spacing: 10) {
                    let statuses = ["claimed", "ordered", "delivered", "completed"]
                    let currentIndex = statuses.firstIndex(of: order.status) ?? 0

                    ForEach(Array(statuses.enumerated()), id: \.element) { index, _ in
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
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                            .padding(.top, 20)
                            .padding(.bottom, 5)
                        Text("Order Complete")
                            .font(.title2).bold().foregroundColor(.orange)

                        if order.fulfillerRating != nil || ratingSubmitted {
                            let displayRating = order.fulfillerRating ?? Double(selectedRating)
                            Text("You rated this fulfiller \(Int(displayRating))★")
                                .font(.subheadline).foregroundColor(.secondary)
                        } else {
                            Text("How was your fulfiller?")
                                .font(.subheadline).foregroundColor(.secondary)

                            HStack(spacing: 12) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= selectedRating ? "star.fill" : "star")
                                        .font(.title)
                                        .foregroundColor(.orange)
                                        .onTapGesture {
                                            selectedRating = star
                                        }
                                }
                            }
                            .padding(.vertical, 4)

                            Button(action: submitRating) {
                                Text("Submit Rating")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange)
                                    .cornerRadius(12)
                            }
                        }
                    }

                } else if order.status == "delivered" {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("READY TO PICKUP PROOF")
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
                                    Text("No photo provided.")
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
                        Text("Your order is being prepared.")
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
        .onAppear { listenToOrder() }
    }

    var statusMessage: String {
        switch order.status {
        case "claimed": return "Fulfiller is preparing to order."
        case "ordered": return "Food is ordered and being prepared"
        case "delivered": return "Your food is ready-for-pickup."
        case "completed": return "Order complete."
        default: return "Waiting for a fulfiller..."
        }
    }

    func listenToOrder() {
        guard let orderId = initialOrder.id else { return }
        db.collection("orders").document(orderId)
            .addSnapshotListener { snapshot, _ in
                guard let snapshot = snapshot else { return }
                self.liveOrder = try? snapshot.data(as: Order.self)
            }
    }

    func confirmReceipt() {
        isConfirming = true
        let paymentController = PaymentController()

        Task {
            let paid = await paymentController.payoutFulfiller(orderId: order.id ?? "")
            if paid {
                db.collection("orders").document(order.id ?? "")
                    .updateData(["status": "completed"]) { error in
                        isConfirming = false
                        if let error = error {
                            print("Error completing order: \(error.localizedDescription)")
                        }
                    }
            } else {
                isConfirming = false
                print("Payout failed")
            }
        }
    }

    func submitRating() {
        guard let orderId = order.id, let fulfillerId = order.fulfillerId, !fulfillerId.isEmpty else { return }
        let rating = Double(selectedRating)
        ratingSubmitted = true

        db.collection("orders").document(orderId).updateData([
            "fulfillerRating": rating
        ])

        let fulfillerRef = db.collection("users").document(fulfillerId)
        fulfillerRef.getDocument { snapshot, _ in
            guard let data = snapshot?.data() else { return }

            let currentRating = data["rating"] as? Double ?? 5.0
            let totalRatings = data["totalRatingsReceived"] as? Int ?? 0

            let newTotal = totalRatings + 1
            let newAverage = ((currentRating * Double(totalRatings)) + rating) / Double(newTotal)

            fulfillerRef.updateData([
                "rating": newAverage,
                "totalRatingsReceived": newTotal
            ])
        }
    }
}
