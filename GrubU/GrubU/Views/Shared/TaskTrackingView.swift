//
//  TaskTrackingView.swift
//
//  Fulfiller workflow: advance status, upload proof, etc.
//
//  Created by Julie Baguio on 4/7/26.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage

struct TaskTrackingView: View {
    let initialOrder: Order
    @EnvironmentObject var activityController: ActivityController
    @Environment(\.earnPostClaimNavigation) private var earnPostClaimNavigation
    @Environment(\.dismiss) var dismiss
    private var db = Firestore.firestore()

    @State private var liveOrder: Order?
    @State private var orderListener: ListenerRegistration?
    @State private var pickupName: String = ""
    @State private var estimatedTime: String = ""
    @State private var grubhubOrderId: String = ""
    @State private var hasConfirmedItems = false

    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var isUploading = false

    @StateObject private var marketController = MarketController()
    @State private var showReleaseConfirmation = false
    @State private var isReleasing = false
    @State private var releaseErrorMessage: String?
    @State private var showReleasedSuccessAlert = false

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
                    let pipeline = OrderStatusPresentation.fulfillerProgressPipeline
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
                        Text(OrderStatusPresentation.shortLabel(status: order.status, role: .fulfiller))
                            .font(.title2).bold()
                            .foregroundStyle(.primary)
                        Text(OrderStatusPresentation.detailMessage(status: order.status, role: .fulfiller))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if order.status == "claimed" {
                        Divider()
                            .background(Color(.separator).opacity(0.55))

                        VStack(alignment: .leading, spacing: 20) {
                            CustomTextField(
                                label: "Pickup name",
                                placeholder: "Name you used to order",
                                text: $pickupName
                            )
                            CustomTextField(
                                label: "Estimated ready time",
                                placeholder: "e.g. 12:20 PM",
                                text: $estimatedTime
                            )
                            CustomTextField(
                                label: "Grubhub order #",
                                placeholder: "From your Grubhub receipt",
                                text: $grubhubOrderId
                            )

                            Toggle(isOn: $hasConfirmedItems) {
                                Text("I confirm that I placed the order exactly as requested.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .toggleStyle(CheckboxToggleStyle())
                        }

                    } else if order.status == "ordered" {
                        Divider()
                            .background(Color(.separator).opacity(0.55))

                        VStack(alignment: .leading, spacing: 15) {
                            Text("Grubhub screenshot")
                                .font(.headline)

                            Button(action: { showImagePicker = true }) {
                                VStack {
                                    if let selectedImage = selectedImage {
                                        Image(uiImage: selectedImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 150)
                                            .clipped()
                                    } else {
                                        Image(systemName: "plus")
                                            .font(.title)
                                        Text("UPLOAD")
                                            .fontWeight(.bold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 150)
                                .background(AppTheme.pageBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(
                                            Color(.separator).opacity(0.6),
                                            style: StrokeStyle(lineWidth: 2, dash: selectedImage == nil ? [5] : [])
                                        )
                                )
                            }
                            .foregroundColor(selectedImage == nil ? .primary : .clear)

                            Text("Tap above to attach a screenshot from the Grubhub app.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer(minLength: 8)

                    if order.status != "delivered" && order.status != "completed" {
                        Button(action: submitOrderUpdate) {
                            HStack {
                                if isUploading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .padding(.trailing, 5)
                                }
                                Text(isUploading ? "Uploading..." : buttonLabel)
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid && !isUploading ? AppTheme.accent : Color(.separator).opacity(0.55))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .disabled(!isFormValid || isUploading)

                        if order.status == "claimed" {
                            VStack(alignment: .leading, spacing: 8) {
                                Button(role: .destructive) {
                                    releaseErrorMessage = nil
                                    showReleaseConfirmation = true
                                } label: {
                                    HStack {
                                        if isReleasing {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                                .padding(.trailing, 5)
                                        }
                                        Text(isReleasing ? "Releasing…" : "Cancel order")
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
                                .disabled(isReleasing || isUploading)

                                Text("You can cancel until you place the order on Grubhub.")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)

                                if let releaseErrorMessage {
                                    Text(releaseErrorMessage)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    } else if order.status == "completed" {
                        Divider()
                            .background(Color(.separator).opacity(0.55))

                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(AppTheme.accent)
                                .padding(.bottom, 5)
                            Text(OrderStatusPresentation.shortLabel(status: "completed", role: .fulfiller))
                                .font(.title3).bold()
                                .foregroundStyle(AppTheme.accent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
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
        .navigationTitle("Track Task")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            listenToOrder()
            let oid = initialOrder.id ?? ""
            if !oid.isEmpty {
                activityController.setActiveTaskDetailOrderId(oid)
                activityController.markTaskOrderSeen(oid)
            }
        }
        .onDisappear {
            activityController.setActiveTaskDetailOrderId(nil)
            earnPostClaimNavigation?.clearPostClaimIfMatches(orderId: initialOrder.id)
            orderListener?.remove()
            orderListener = nil
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .alert(
            "Cancel this order?",
            isPresented: $showReleaseConfirmation
        ) {
            Button("Keep order", role: .cancel) {}
            Button("Cancel order", role: .destructive) {
                releaseClaimedOrder()
            }
        } message: {
            Text("The request will be returned to the marketplace for someone else to accept.")
        }
        .alert(
            "Order cancelled",
            isPresented: $showReleasedSuccessAlert
        ) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("This order has been returned to the marketplace.")
        }
    }

    private func releaseClaimedOrder() {
        guard let orderId = order.id, !orderId.isEmpty else { return }
        guard let fulfillerId = order.fulfillerId, !fulfillerId.isEmpty else { return }
        isReleasing = true
        releaseErrorMessage = nil
        marketController.releaseClaimedOrder(orderId: orderId, fulfillerId: fulfillerId) { success in
            DispatchQueue.main.async {
                isReleasing = false
                if success {
                    earnPostClaimNavigation?.clearPostClaimIfMatches(orderId: orderId)
                    showReleasedSuccessAlert = true
                } else {
                    releaseErrorMessage = "Couldn’t release this order — its status may have changed."
                }
            }
        }
    }
    
    // --- UI Helpers ---
    var buttonLabel: String {
        order.status == "claimed" ? "Confirm & Mark as Ordered" : "Submit proof & notify requester"
    }
    
    var isFormValid: Bool {
        if order.status == "claimed" {
            return !pickupName.isEmpty && !estimatedTime.isEmpty && hasConfirmedItems
        } else if order.status == "ordered" {
            return selectedImage != nil
        }
        return false
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

    private func updateFirestore(with updateData: [String: Any]) {
        db.collection("orders").document(order.id ?? "").updateData(updateData) { error in
            isUploading = false
            if let error = error {
                print("Error updating document: \(error.localizedDescription)")
            }
        }
    }

    func submitOrderUpdate() {
        let nextStatus = order.status == "claimed" ? "ordered" : "delivered"
        var updateData: [String: Any] = ["status": nextStatus]
        
        if order.status == "claimed" {
            updateData["pickupName"] = pickupName
            updateData["estimatedTime"] = estimatedTime
            updateData["grubhubOrderId"] = grubhubOrderId
            
            updateFirestore(with: updateData)
            
        } else if order.status == "ordered" {
            guard let image = selectedImage else { return }
            isUploading = true
            
            uploadImageToStorage(image: image) { url in
                if let downloadUrl = url {
                    updateData["proofImageUrl"] = downloadUrl
                }
                updateFirestore(with: updateData)
            }
        }
    }
    
    private func uploadImageToStorage(image: UIImage, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(nil)
            return
        }
        
        let filename = UUID().uuidString
        let storageRef = Storage.storage().reference().child("delivery_proofs/\(filename).jpg")
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Failed to upload image: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Failed to get download URL: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                completion(url?.absoluteString)
            }
        }
    }
}

struct CustomTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)
                .foregroundColor(.primary)
            TextField(placeholder, text: $text)
                .padding()
                .background(AppTheme.pageBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(.separator).opacity(0.45), lineWidth: 1)
                )
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundStyle(configuration.isOn ? AppTheme.accent : Color.secondary)
                .onTapGesture { configuration.isOn.toggle() }
            configuration.label
        }
    }
}
