//
//  AuthController.swift
//
//  Firebase auth listener + sign out. Session only if email’s verified.
//
//  Created by Julie Baguio on 4/7/26.
//
import Foundation
import FirebaseAuth
import SwiftUI
import Combine

class AuthController: ObservableObject {
    @Published var userSession: FirebaseAuth.User?

    init() {
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user, user.isEmailVerified {
                self?.userSession = user
            } else {
                self?.userSession = nil
            }
        }
    }

    func refreshVerification() {
        Auth.auth().currentUser?.reload { [weak self] _ in
            DispatchQueue.main.async {
                if let user = Auth.auth().currentUser, user.isEmailVerified {
                    self?.userSession = user
                }
            }
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
    }
}
