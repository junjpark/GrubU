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
    @StateObject private var intentRefresh = IntentRefreshSignal()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.userSession == nil {
                    LoginView()
                } else if let uid = authManager.userSession?.uid {
                    Group {
                        if UserIntentStore.intent(for: uid) != nil {
                            MainTabView()
                        } else {
                            IntentOnboardingView(uid: uid) {
                                intentRefresh.bump()
                            }
                        }
                    }
                    .id(intentRefresh.generation)
                } else {
                    MainTabView()
                }
            }
            .environmentObject(authManager)
        }
    }
}
