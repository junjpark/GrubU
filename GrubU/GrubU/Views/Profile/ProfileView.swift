//
//  ProfileView.swift
//
//  You, quick stats, bank link, archive, sign out.
//
//  Created by Julie Baguio on 4/7/26.
//
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authController: AuthController
    @EnvironmentObject var activityController: ActivityController
    @State private var currentUser: User? = nil
    @State private var userListener: ListenerRegistration?

    private var jobsCompletedCount: Int {
        activityController.fulfillingTasks.filter { $0.status == "completed" }.count
    }

    private var requestsMadeCount: Int {
        activityController.requestedOrders.count
    }

    private var totalEarnings: Double {
        activityController.fulfillingTasks
            .filter { $0.status == "completed" }
            .reduce(0) { $0 + $1.bountyAmount }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: 64, height: 64)
                            Text(initials)
                                .font(.title2.bold())
                                .foregroundStyle(.orange)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentUser?.displayName ?? "Loading…")
                                .font(.title3.bold())
                            Text(ratingLine)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Stats") {
                    HStack {
                        Text("Jobs completed")
                        Spacer()
                        Text("\(jobsCompletedCount)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Requests made")
                        Spacer()
                        Text("\(requestsMadeCount)")
                            .foregroundStyle(.secondary)
                    }
                    if totalEarnings > 0 {
                        HStack {
                            Text("Total earned (bounties)")
                            Spacer()
                            Text("$\(totalEarnings, specifier: "%.2f")")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section(header: Text("Account")) {
                    if let email = currentUser?.email {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(email)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let uni = currentUser?.university, !uni.isEmpty {
                        HStack {
                            Text("University")
                            Spacer()
                            Text(uni)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section(header: Text("Archive")) {
                    NavigationLink(destination: ProfileArchiveView()) {
                        HStack {
                            Image(systemName: "archivebox.fill")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("History")
                                Text("Completed jobs & requests")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section(header: Text("Payments")) {
                    NavigationLink(destination: BankLinkView()) {
                        HStack {
                            Image(systemName: "building.columns.fill")
                                .foregroundStyle(.orange)
                            Text("Link bank account")
                            Spacer()
                            if currentUser?.stripeConnectAccountId != nil {
                                Text("Connected")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            } else {
                                Text("Not set up")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        authController.signOut()
                    } label: {
                        Text("Sign out")
                    }
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                fetchUserData()
                if let uid = authController.userSession?.uid {
                    activityController.fetchActivity(for: uid)
                }
            }
            .onDisappear {
                userListener?.remove()
                userListener = nil
            }
        }
    }

    private var initials: String {
        let name = currentUser?.displayName ?? "?"
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first.map(String.init) }
        let s = letters.joined()
        return s.isEmpty ? "?" : s.uppercased()
    }

    private var ratingLine: String {
        guard let r = currentUser?.rating else { return "No rating yet" }
        return String(format: "%.1f ★", r)
    }

    private static func intFromFirestore(_ value: Any?) -> Int? {
        switch value {
        case let i as Int: return i
        case let i as Int64: return Int(i)
        case let i as UInt64: return Int(i)
        case let d as Double where d.rounded() == d: return Int(d)
        default: return nil
        }
    }

    func fetchUserData() {
        guard let uid = authController.userSession?.uid else {
            print("ProfileView: No user session found")
            return
        }

        userListener?.remove()

        let db = Firestore.firestore()
        userListener = db.collection("users").document(uid).addSnapshotListener { snapshot, error in
            if let error {
                print("ProfileView: Firestore error - \(error.localizedDescription)")
                return
            }

            guard let document = snapshot, document.exists else {
                print("ProfileView: Document does not exist for uid \(uid)")
                return
            }

            do {
                var user = try document.data(as: User.self)
                if let data = document.data() {
                    if let co = Self.intFromFirestore(data["completedOrders"]) {
                        user.completedOrders = co
                    }
                    if let tr = Self.intFromFirestore(data["totalRatingsReceived"]) {
                        user.totalRatingsReceived = tr
                    }
                }
                DispatchQueue.main.async {
                    self.currentUser = user
                }
            } catch {
                print("ProfileView: Failed to decode User - \(error)")
            }
        }
    }
}
