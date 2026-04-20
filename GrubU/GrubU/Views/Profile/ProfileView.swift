//
//  ProfileView.swift
//
//  Full-width dashboard: name header, activity drill-downs, settings.
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

    private var ordersCompletedCount: Int {
        activityController.fulfillingTasks.filter { $0.status == "completed" }.count
    }

    private var completedRequestsCount: Int {
        activityController.requestedOrders.filter { $0.status == "completed" }.count
    }

    private var totalEarnings: Double {
        activityController.fulfillingTasks
            .filter { $0.status == "completed" }
            .reduce(0) { $0 + $1.bountyAmount }
    }

    private var orangeRed: Color { AppTheme.accent }
    private var pageBackground: Color { AppTheme.pageBackground }
    private var modalBeige: Color { AppTheme.surfaceBackground }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .center, spacing: 6) {
                            VStack(alignment: .center, spacing: 6) {
                                Text(currentUser?.displayName ?? "Loading…")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundStyle(orangeRed)
                                if let email = currentUser?.email {
                                    Text(email)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                if let uni = currentUser?.university, !uni.isEmpty {
                                    Text(uni)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                        }

                        sectionTitle("Activity", systemImage: "chart.bar.fill")
                        modalCard {
                            VStack(spacing: 0) {
                                NavigationLink(destination: ProfileOrdersArchiveView()) {
                                    activityDrillDownRow(
                                        label: "Completed orders",
                                        valueText: "\(ordersCompletedCount)"
                                    )
                                }
                                .buttonStyle(.plain)

                                fullWidthDivider()

                                NavigationLink(destination: ProfileRequestsArchiveView()) {
                                    activityDrillDownRow(
                                        label: "Completed requests",
                                        valueText: "\(completedRequestsCount)"
                                    )
                                }
                                .buttonStyle(.plain)

                                fullWidthDivider()

                                activityStaticRow(
                                    label: "Rating",
                                    valueText: ratingLine
                                )

                                fullWidthDivider()

                                activityStaticRow(
                                    label: "Total earned",
                                    valueText: String(format: "$%.2f", totalEarnings)
                                )
                            }
                        }

                        sectionTitle("Settings", systemImage: "gearshape.fill")
                        modalCard {
                            VStack(spacing: 0) {
                                NavigationLink(destination: BankLinkView()) {
                                    actionRow(
                                        label: "Link bank account",
                                        value: currentUser?.stripeConnectAccountId != nil ? "Connected" : "Not set up",
                                        valueColor: currentUser?.stripeConnectAccountId != nil ? orangeRed : .primary,
                                        showsChevron: true
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Button(role: .destructive) {
                            authController.signOut()
                        } label: {
                            filledSignOutButton(label: "Sign out")
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, ProfileLayout.horizontalPadding)
                    .padding(.top, 18)

                    Spacer(minLength: 24)
                }
                .padding(.bottom, AppTheme.tabBarBottomClearance)
            }
            .background(pageBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
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

    // MARK: - Row builders (layout only)

    @ViewBuilder
    private func modalCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(modalBeige)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
            )
    }

    private func sectionTitle(_ text: String, systemImage: String? = nil) -> some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(orangeRed)
            }
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(orangeRed)
                .textCase(.uppercase)
                .tracking(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    private func activityDrillDownRow(label: String, valueText: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 16)
            Text(valueText)
                .font(.body.weight(.semibold))
                .foregroundStyle(orangeRed)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .padding(.leading, 6)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }

    private func activityStaticRow(label: String, valueText: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 16)
            Text(valueText)
                .font(.body.weight(.semibold))
                .foregroundStyle(orangeRed)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }

    private func actionRow(
        label: String,
        value: String,
        valueColor: Color,
        showsChevron: Bool,
        labelColor: Color = .secondary
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(labelColor)
            Spacer(minLength: 16)
            if !value.isEmpty {
                Text(value)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(valueColor)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 6)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }

    private func filledSignOutButton(label: String) -> some View {
        HStack {
            Spacer()
            Text(label)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(orangeRed)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(Rectangle())
    }

    private func fullWidthDivider() -> some View {
        Divider()
            .background(Color(.separator))
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
