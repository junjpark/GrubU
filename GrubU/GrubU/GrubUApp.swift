//
//  GrubUApp.swift
//  GrubU
//
//  Created by user287016 on 4/6/26.
//

// File: GrubU/GrubUApp.swift
import SwiftUI
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct GrubUApp: App {
    // Create ONE instance of the manager for the whole app to share
    @StateObject var authManager = AuthController()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            // THE TRAFFIC COP:
            if authManager.userSession != nil {
                // If they are logged in and verified, show the Feed!
                MarketFeedView()
            } else {
                // If they aren't, force them to log in!
                LoginView()
            }
        }
        // This injects the manager into the app so any screen can access it
        .environmentObject(authManager)
    }
}
