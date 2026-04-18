//
//  BankLinkView.swift
//  
//
//  Created by Julie Baguio on 4/7/26.
//
import SwiftUI
import SafariServices
struct BankLinkView: View {
    @StateObject private var paymentController = PaymentController()
    @State private var showSafari = false
    @State private var onboardingURL: URL?
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "banknote.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            Text("Link Your Bank Account")
                .font(.title2.bold())
            Text("To receive bounty payouts for fulfilled orders, you need to connect a bank account through Stripe.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Connect with Stripe") {
                Task {
                    if let urlString = await paymentController.createConnectAccount(),
                       let url = URL(string: urlString) {
                        onboardingURL = url
                        showSafari = true
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding()
        .sheet(isPresented: $showSafari) {
            if let url = onboardingURL {
                SafariView(url: url)
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
