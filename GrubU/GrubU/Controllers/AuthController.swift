//
//  AuthController.swift
//  
//
//  Created by Julie Baguio on 4/7/26.
//
import Foundation
import FirebaseAuth
import SwiftUI
import Combine

class AuthController: ObservableObject {
    // This variable broadcasts its state to the whole app
    @Published var userSession: FirebaseAuth.User?
    
    init() {
        // This listener runs in the background forever.
        // It fires automatically whenever someone logs in, logs out, or signs up.
        _ = Auth.auth().addStateDidChangeListener { auth, user in
            
            // Only consider them "logged in" to the app if they clicked the email link!
            if let user = user, user.isEmailVerified {
                self.userSession = user
            } else {
                self.userSession = nil
            }
        }
    }
    
    // A simple global logout function we can call from the Home screen later
    func signOut() {
        try? Auth.auth().signOut()
    }
}
