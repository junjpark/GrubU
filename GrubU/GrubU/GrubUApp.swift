//
//  GrubUApp.swift
//
//  App entry: Firebase + push, then login / intent / tabs.
//
//  Created by user287016 on 4/6/26.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import FirebaseFirestore
import UserNotifications
import FirebaseAuth
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        FirebaseApp.configure()
        
        // Request Notification Permission
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if granted {
                print("Notification permission granted.")
            }
        }
        
        application.registerForRemoteNotifications()
        Messaging.messaging().delegate = self

        // Keep list/collection screens aligned with the app's white + warm surface palette.
        UITableView.appearance().backgroundColor = UIColor(AppTheme.pageBackground)
        UICollectionView.appearance().backgroundColor = UIColor(AppTheme.pageBackground)

        RestaurantImageCache.warmConfigureURLSessionDefaults()

        return true
    }
    
    // 2. Capture the FCM Token and save it to the current user's profile
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("Firebase registration token: \(token)")
        
        // If the user is logged in, save this token to their Firestore user document
        // so our Cloud Function knows where to send the push notification.
        if let uid = Auth.auth().currentUser?.uid {
            Firestore.firestore().collection("users").document(uid).setData(["fcmToken": token], merge: true)
        }
    }
}

@main
struct GrubUApp: App {
    @StateObject var authManager = AuthController()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.userSession == nil {
                    LoginView()
                } else {
                    MainTabView()
                }
            }
            .environmentObject(authManager)
            .fontDesign(.rounded)
        }
    }
}
