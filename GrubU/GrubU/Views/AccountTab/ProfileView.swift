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
                            Text(currentUser?.university ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)

                    if let email = currentUser?.email {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(email)
                                .foregroundColor(.secondary)
                        }
                    }
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

                Section(header: Text("Payments")) {
                    NavigationLink(destination: BankLinkView()) {
                        HStack {
                            Image(systemName: "building.columns.fill")
                                .foregroundColor(.orange)
                            Text("Link Bank Account")
                            Spacer()
                            if currentUser?.stripeConnectAccountId != nil {
                                Text("Connected")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Text("Not Set Up")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
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
        guard let uid = authController.userSession?.uid else {
            print("ProfileView: No user session found")
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(uid).addSnapshotListener { snapshot, error in
            if let error = error {
                print("ProfileView: Firestore error - \(error.localizedDescription)")
                return
            }

            guard let document = snapshot, document.exists else {
                print("ProfileView: Document does not exist for uid \(uid)")
                return
            }

            do {
                self.currentUser = try document.data(as: User.self)
            } catch {
                print("ProfileView: Failed to decode User - \(error)")
            }
        }
    }
}
