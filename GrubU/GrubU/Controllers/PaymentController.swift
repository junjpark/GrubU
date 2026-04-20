//
//  PaymentController.swift
//
//  Calls your cloud function + spins up the Stripe payment sheet.
//
//  Created by user287016 on 4/18/26.
//

import Foundation
import FirebaseAuth
import FirebaseFunctions
import StripePaymentSheet
import Combine

@MainActor
class PaymentController: ObservableObject {
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let functions = Functions.functions()

    func preparePaymentSheet(amount: Double) async {
        isLoading = true
        errorMessage = nil

        let amountInCents = Int(amount * 100)

        do {
            let result = try await functions.httpsCallable("createPaymentIntent")
                .call(["amount": amountInCents])

            guard let data = result.data as? [String: Any],
                  let clientSecret = data["paymentIntent"] as? String,
                  let ephemeralKey = data["ephemeralKey"] as? String,
                  let customerId = data["customer"] as? String,
                  let publishableKey = data["publishableKey"] as? String
            else {
                errorMessage = "Invalid response from server."
                isLoading = false
                return
            }

            STPAPIClient.shared.publishableKey = publishableKey

            var config = PaymentSheet.Configuration()
            config.merchantDisplayName = "GrubU"
            config.customer = .init(id: customerId, ephemeralKeySecret: ephemeralKey)
            config.allowsDelayedPaymentMethods = false

            self.paymentSheet = PaymentSheet(
                paymentIntentClientSecret: clientSecret,
                configuration: config
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func createConnectAccount() async -> String? {
        do {
            let result = try await functions.httpsCallable("createConnectAccount").call()
            guard let data = result.data as? [String: Any],
                  let url = data["url"] as? String else { return nil }
            return url
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func payoutFulfiller(orderId: String) async -> Bool {
        do {
            _ = try await functions.httpsCallable("payoutFulfiller")
                .call(["orderId": orderId])
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
