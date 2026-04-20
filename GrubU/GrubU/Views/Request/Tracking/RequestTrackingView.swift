//
//  RequestTrackingView.swift
//
//  Requester-side live order tracker + confirm delivered stuff.
//
//  Created by Julie Baguio on 4/7/26.
//

import SwiftUI
import FirebaseFirestore

struct RequestTrackingView: View {
    let initialOrder: Order
    @EnvironmentObject var activityController: ActivityController
    @Environment(\.dismiss) var dismiss
    private var db = Firestore.firestore()

    @State private var liveOrder: Order?
    @State private var orderListener: ListenerRegistration?
    @State private var isConfirming = false
    @State private var selectedRating: Int = 5
    @State private var ratingSubmitted = false

    @StateObject private var marketController = MarketController()
    @State private var showCancelConfirmation = false
    @State private var isCanceling = false
    @State private var cancelErrorMessage: String?
    @State private var showCancelledSuccessAlert = false

    init(order: Order) {
        self.initialOrder = order
    }

    private var order: Order {
        liveOrder ?? initialOrder
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 10) {
                    let pipeline = OrderStatusPresentation.requesterProgressPipeline
                    let currentIndex = OrderStatusPresentation.progressIndex(pipeline: pipeline, status: order.status)

                    ForEach(0..<pipeline.count, id: \.self) { index in
                        Rectangle()
                            .frame(height: 8)
                            .foregroundStyle(index <= currentIndex ? AppTheme.accent : Color(.separator).opacity(0.45))
                            .cornerRadius(4)
                    }
                }
                .padding(14)
                .profileModalCardStyle()

                OrderLineItemsSummaryCard(order: order)

                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(OrderStatusPresentation.shortLabel(status: order.status, role: .requester))
                            .font(.title2).bold()
                            .foregroundStyle(.primary)
                        Text(OrderStatusPresentation.detailMessage(status: order.status, role: .requester))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if order.status == "open" {
                        Divider()
                            .background(Color(.separator).opacity(0.55))

                        VStack(alignment: .leading, spacing: 8) {
                            Button(role: .destructive) {
                                cancelErrorMessage = nil
                                showCancelConfirmation = true
                            } label: {
                                HStack {
                                    if isCanceling {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                            .padding(.trailing, 5)
                                    }
                                    Text(isCanceling ? "Canceling…" : "Cancel request")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.red)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 16)
                                .background(AppTheme.surfaceBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.red.opacity(0.35), lineWidth: 1)
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(isCanceling)

                            Text("You can cancel until someone accepts your request.")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)

                            if let cancelErrorMessage {
                                Text(cancelErrorMessage)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    } else if order.status == "completed" {
                        Divider()
                            .background(Color(.separator).opacity(0.55))
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(AppTheme.accent)
                                .padding(.top, 8)
                                .padding(.bottom, 5)

                            if order.fulfillerRating != nil || ratingSubmitted {
                                Text("You rated this fulfiller \(Int(order.fulfillerRating ?? Double(selectedRating)))★")
                                    .font(.subheadline).foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            } else {
                                Text("How was your fulfiller?")
                                    .font(.subheadline).foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)

                                HStack(spacing: 12) {
                                    ForEach(1...5, id: \.self) { star in
                                        Image(systemName: star <= selectedRating ? "star.fill" : "star")
                                            .font(.title)
                                            .foregroundStyle(AppTheme.accent)
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
                                        .background(AppTheme.accent)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)

                    } else if order.status == "delivered" {
                        Divider()
                            .background(Color(.separator).opacity(0.55))

                        VStack(alignment: .leading, spacing: 15) {
                            Text("Grubhub proof")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)

                            if let imageUrlString = order.proofImageUrl,
                               !imageUrlString.isEmpty,
                               let validURL = URL(string: imageUrlString) {
                                AsyncImage(url: validURL) { image in
                                    image.resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    ZStack {
                                        AppTheme.surfaceBackground
                                        ProgressView()
                                    }
                                }
                                .frame(height: 250)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            } else {
                                ZStack {
                                    AppTheme.surfaceBackground
                                    VStack(spacing: 10) {
                                        Image(systemName: "photo.badge.exclamationmark")
                                            .font(.largeTitle)
                                            .foregroundStyle(.secondary)
                                        Text("No photo provided.")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(height: 250)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
                                )
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
                            .background(AppTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .disabled(isConfirming)
                        .padding(.top, 4)

                    }
                }
                .padding(16)
                .profileModalCardStyle()
            }
            .padding(.horizontal)
            .padding(.bottom, AppTheme.tabBarBottomClearance)
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.pageBackground)
        .navigationTitle("Track Request")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            listenToOrder()
            let oid = initialOrder.id ?? ""
            if !oid.isEmpty {
                activityController.setActiveRequestDetailOrderId(oid)
                activityController.markRequestOrderSeen(oid)
            }
        }
        .onDisappear {
            activityController.setActiveRequestDetailOrderId(nil)
            orderListener?.remove()
            orderListener = nil
        }
        .alert(
            "Cancel this request?",
            isPresented: $showCancelConfirmation
        ) {
            Button("Keep request", role: .cancel) {}
            Button("Cancel request", role: .destructive) {
                cancelOpenRequest()
            }
        } message: {
            Text("Your request will be removed from the marketplace. This can’t be undone.")
        }
        .alert(
            "Request cancelled",
            isPresented: $showCancelledSuccessAlert
        ) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Your request has been removed from the marketplace.")
        }
    }

    private func cancelOpenRequest() {
        guard let orderId = order.id, !orderId.isEmpty else { return }
        isCanceling = true
        cancelErrorMessage = nil
        marketController.cancelOpenRequest(orderId: orderId) { success in
            DispatchQueue.main.async {
                isCanceling = false
                if success {
                    showCancelledSuccessAlert = true
                } else {
                    cancelErrorMessage = "Couldn’t cancel — someone may have just accepted your request."
                }
            }
        }
    }

    func listenToOrder() {
        orderListener?.remove()
        guard let orderId = initialOrder.id else { return }
        orderListener = db.collection("orders").document(orderId)
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

        // fulfiller profile is updated by Cloud Function syncFulfillerRatingFromOrder
        // (requesters cannot write other users' documents under typical Firestore rules).
        db.collection("orders").document(orderId).updateData([
            "fulfillerRating": rating
        ]) { error in
            if let error = error {
                print("submitRating: order update failed - \(error.localizedDescription)")
                DispatchQueue.main.async { ratingSubmitted = false }
            }
        }
    }
}
