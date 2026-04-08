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
    @StateObject var authManager = AuthController()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.userSession != nil {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .environmentObject(authManager)
    }
}
