import SwiftUI
import FirebaseFirestore

struct TaskTrackingView: View {
    let order: Order
    @Environment(\.dismiss) var dismiss
    private var db = Firestore.firestore()
    
    // Form State
    @State private var pickupName: String = ""
    @State private var estimatedTime: String = ""
    @State private var grubhubOrderId: String = ""
    @State private var hasConfirmedItems = false
    
    // Photo State
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    
    // EXPLICIT INIT ADDED HERE TO FIX ACTIVITYMAINVIEW ERROR
    init(order: Order) {
        self.order = order
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                
                // 1. PROGRESS BAR
                HStack(spacing: 10) {
                    let statuses = ["claimed", "ordered", "delivered"]
                    let currentIndex = statuses.firstIndex(of: order.status) ?? 0
                    
                    ForEach(Array(statuses.enumerated()), id: \.element) { index, step in
                        Rectangle()
                            .frame(height: 8)
                            .foregroundColor(index <= currentIndex ? .green : .gray.opacity(0.3))
                            .cornerRadius(4)
                    }
                }
                .padding(.top)

                // 2. CURRENT STATUS HEADER
                VStack(alignment: .leading, spacing: 10) {
                    Text("Current Status: \(order.status.uppercased())")
                        .font(.caption).bold().foregroundColor(.secondary)
                    Text(statusMessage)
                        .font(.title2).bold()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                // 3. ACTIONABLE FORMS
                if order.status == "claimed" {
                    VStack(alignment: .leading, spacing: 20) {
                        CustomTextField(label: "Pickup Name", placeholder: "Enter name used for pickup", text: $pickupName)
                        CustomTextField(label: "Estimated Ready Time", placeholder: "Enter estimated ready time", text: $estimatedTime)
                        CustomTextField(label: "Order Number (Optional)", placeholder: "Enter order number", text: $grubhubOrderId)
                        
                        Toggle(isOn: $hasConfirmedItems) {
                            Text("I confirm that I placed the order exactly as requested.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .toggleStyle(CheckboxToggleStyle())
                    }
                    
                } else if order.status == "ordered" {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Upload Photo Evidence")
                            .font(.headline)
                        
                        Button(action: { showImagePicker = true }) {
                            VStack {
                                Image(systemName: selectedImage == nil ? "plus" : "checkmark.circle.fill")
                                    .font(.title)
                                Text(selectedImage == nil ? "UPLOAD" : "IMAGE ATTACHED")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 150)
                            .background(Color.gray.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray, style: StrokeStyle(lineWidth: 2, dash: [5]))
                            )
                        }
                        .foregroundColor(selectedImage == nil ? .primary : .green)
                        
                        Text("Please provide a photo of the food at the drop-off location.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer(minLength: 20)
                
                // 4. SUBMIT BUTTON
                if order.status != "delivered" {
                    Button(action: submitOrderUpdate) {
                        Text(buttonLabel)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.green : Color.gray.opacity(0.5))
                            .cornerRadius(12)
                    }
                    .disabled(!isFormValid)
                } else {
                    VStack {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                            .padding(.bottom, 5)
                        Text("Order Complete! 🏁")
                            .font(.title3).bold().foregroundColor(.green)
                    }
                    .padding(.top, 20)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Track Task")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // --- UI Helpers ---
    
    var statusMessage: String {
        switch order.status {
        case "claimed": return "Head to Grubhub/Meal Plan to place the order."
        case "ordered": return "Food is on the way. Upload a photo when dropped off."
        case "delivered": return "Delivery complete! Great job."
        default: return "Unknown status"
        }
    }
    
    var buttonLabel: String {
        order.status == "claimed" ? "Confirm & Mark as Ordered" : "Submit Photo & Mark as Delivered"
    }
    
    // --- Logic Helpers ---

    var isFormValid: Bool {
        if order.status == "claimed" {
            return !pickupName.isEmpty && !estimatedTime.isEmpty && hasConfirmedItems
        } else if order.status == "ordered" {
            return selectedImage != nil
        }
        return false
    }

    func submitOrderUpdate() {
        let nextStatus = order.status == "claimed" ? "ordered" : "delivered"
        var updateData: [String: Any] = ["status": nextStatus]
        
        if order.status == "claimed" {
            updateData["pickupName"] = pickupName
            updateData["estimatedTime"] = estimatedTime
            updateData["grubhubOrderId"] = grubhubOrderId
        }
        
        db.collection("orders").document(order.id ?? "").updateData(updateData) { error in
            if error == nil {
                // Optional: Dismiss view or just let the snapshot listener update the UI
            }
        }
    }
}

// MARK: - Reusable Components (MUST BE OUTSIDE THE MAIN STRUCT)

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
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1))
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .green : .gray)
                .onTapGesture { configuration.isOn.toggle() }
            configuration.label
        }
    }
}
