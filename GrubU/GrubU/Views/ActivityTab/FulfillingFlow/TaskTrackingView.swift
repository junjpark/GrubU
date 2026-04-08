import SwiftUI
import FirebaseFirestore
import FirebaseStorage

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
    @State private var isUploading = false
    
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
                            .foregroundColor(index <= currentIndex ? .green : .gray.opacity(0.3))
                            .cornerRadius(4)
                    }
                }
                .padding(.top)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Current Status: \(order.status.uppercased())")
                        .font(.caption).bold().foregroundColor(.secondary)
                    Text(statusMessage)
                        .font(.title2).bold()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

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
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray, style: StrokeStyle(lineWidth: 2, dash: selectedImage == nil ? [5] : []))
                            )
                        }
                        .foregroundColor(selectedImage == nil ? .primary : .clear) // Hide text color if image exists
                        
                        Text("Please provide a photo of the food at the drop-off location.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer(minLength: 20)
                
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
                        .background(isFormValid && !isUploading ? Color.green : Color.gray.opacity(0.5))
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isUploading)
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
        // Attach the Image Picker Sheet here
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }
    
    // --- UI Helpers ---
    
    var statusMessage: String {
        switch order.status {
        case "claimed": return "Head to Grubhub/Meal Plan to place the order."
        case "ordered": return "Food is on the way. Upload a photo when dropped off."
        case "delivered": return "Delivery complete! Waiting for requester confirmation."
        case "completed": return "Requester confirmed receipt. Great job!"
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

    private func updateFirestore(with updateData: [String: Any]) {
        db.collection("orders").document(order.id ?? "").updateData(updateData) { error in
            isUploading = false
            if error == nil {
            } else {
                print("Error updating document: \(error?.localizedDescription ?? "Unknown error")")
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
            isUploading = true // Show loading spinner
            
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
