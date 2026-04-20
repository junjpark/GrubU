//
//  LoginView.swift
//
//  Email/password in; whines if .edu isn’t verified yet.
//
//  Created by user287016 on 4/7/26.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject var authController: AuthController
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var showResendButton = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.orange.ignoresSafeArea()

                VStack(spacing: 20) {
                    Image("GrubULogo")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 140)
                        .foregroundColor(.white)

                    Text("GrubU")
                        .font(.system(size: 55, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 40)

                    TextField("University Email (.edu)", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding(.horizontal, 30)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 30)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.white)
                            .font(.subheadline)
                            .bold()
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    if !successMessage.isEmpty {
                        Text(successMessage)
                            .foregroundColor(.green)
                            .font(.subheadline)
                            .bold()
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    if showResendButton {
                        Button(action: resendVerificationEmail) {
                            Text("Resend Verification Email")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .underline()
                        }
                        .padding(.top, 5)
                    }

                    Button(action: loginUser) {
                        Text("Login")
                            .font(.headline)
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
                }
            }
        }
    }

    func loginUser() {
        errorMessage = ""
        successMessage = ""
        showResendButton = false

        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error as NSError? {
                let code = AuthErrorCode(rawValue: error.code)
                switch code {
                case .wrongPassword, .invalidCredential:
                    errorMessage = "Incorrect password."
                case .userNotFound:
                    errorMessage = "No account found with that email."
                case .invalidEmail:
                    errorMessage = "Please enter a valid email address."
                case .userDisabled:
                    errorMessage = "This account has been disabled."
                case .tooManyRequests:
                    errorMessage = "Too many attempts. Please try again later."
                default:
                    errorMessage = "Login failed. Please try again."
                }
                return
            }

            guard let user = result?.user else { return }

            user.reload { _ in
                DispatchQueue.main.async {
                    if Auth.auth().currentUser?.isEmailVerified == true {
                        authController.refreshVerification()
                    } else {
                        errorMessage = "Please verify your .edu email address before logging in."
                        showResendButton = true
                    }
                }
            }
        }
    }

    func resendVerificationEmail() {
        errorMessage = ""
        successMessage = "Sending..."

        Auth.auth().currentUser?.sendEmailVerification { error in
            if let error = error {
                successMessage = ""
                errorMessage = "Failed to resend: \(error.localizedDescription)"
            } else {
                successMessage = "A fresh link has been sent to \(email)!"
                showResendButton = false
                try? Auth.auth().signOut()
            }
        }
    }
}
