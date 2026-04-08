//
//  ProfileView.swift
//  
//
//  Created by Julie Baguio on 4/7/26.
//
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authController: AuthController
    @State private var currentUser: User? = nil // Holds the fetched user data
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account Info")) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading) {
                            Text(currentUser?.displayName ?? "Loading...")
                                .font(.headline)
                            Text(currentUser?.university ?? "Washington University in St. Louis")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Stats")) {
                    HStack {
                        Text("Rating")
                        Spacer()
                        Text("\(currentUser?.rating ?? 5.0, specifier: "%.1f") ★")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Balance")
                        Spacer()
                        Text("$\(currentUser?.usdBalance ?? 0.0, specifier: "%.2f")")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Completed Orders")
                        Spacer()
                        Text("\(currentUser?.completedOrders ?? 0)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: {
                        authController.signOut()
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                fetchUserData()
            }
        }
    }
    
    func fetchUserData() {
        guard let uid = authController.userSession?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).addSnapshotListener { snapshot, error in
            guard let document = snapshot else {
                print("Error fetching user: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self.currentUser = try? document.data(as: User.self)
        }
    }
}
