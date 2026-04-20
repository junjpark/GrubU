//
//  BankLinkView.swift
//
//  Stripe Connect onboarding in an in-app Safari sheet.
//
//  Created by Julie Baguio on 4/7/26.
//

import SwiftUI
import SafariServices
import FirebaseAuth
import FirebaseFirestore

struct BankLinkView: View {
    @StateObject private var paymentController = PaymentController()
    @State private var showSafari = false
    @State private var onboardingURL: URL?
    @State private var isConnected = false
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 24) {
            if isConnected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                Text("Bank Account Connected")
                    .font(.title2.bold())
                Text("You're all set to receive bounty payouts for fulfilled orders.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: "banknote.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                Text("Link Your Bank Account")
                    .font(.title2.bold())
                Text("To receive bounty payouts for fulfilled orders, you need to connect a bank account through Stripe.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                if let error = paymentController.errorMessage {
                    Text(error)
                        .foregroundColor(AppTheme.accent)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }

                Button {
                    isLoading = true
                    Task {
                        if let urlString = await paymentController.createConnectAccount(),
                           let url = URL(string: urlString) {
                            onboardingURL = url
                            showSafari = true
                        }
                        isLoading = false
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Connect with Stripe")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(isLoading)
            }
        }
        .padding()
        .onAppear { checkConnectionStatus() }
        .sheet(isPresented: $showSafari, onDismiss: {
            checkConnectionStatus()
        }) {
            if let url = onboardingURL {
                SafariView(url: url)
            }
        }
    }

    func checkConnectionStatus() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid)
            .getDocument { snapshot, _ in
                if let data = snapshot?.data(),
                   let accountId = data["stripeConnectAccountId"] as? String,
                   !accountId.isEmpty {
                    isConnected = true
                }
            }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ vc: SFSafariViewController, context: Context) {}
}
