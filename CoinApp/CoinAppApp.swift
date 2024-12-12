//
//  CoinAppApp.swift
//  CoinApp
//
//  Created by Petru Grigor on 24.11.2024.
//

import SwiftUI
import RevenueCat
import Firebase
import FirebaseMessaging
import AppTrackingTransparency

class AppDelegate: NSObject, UIApplicationDelegate {
    let gcmMessageIDKey = "gcm.Message_ID"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: AppConstants.revenueCatApiKey)
        
        FirebaseApp.configure()
        
        UNUserNotificationCenter.current().delegate = self
        
        Task {
            await handleTrackingAndNotificationPermissions(application: application)
        }
        
        return true
    }
    
    @MainActor
    private func handleTrackingAndNotificationPermissions(application: UIApplication) async {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: authOptions)
            print("Notification authorization granted: \(granted)")
        } catch {
            print("Notification authorization error: \(error.localizedDescription)")
        }
        
        application.registerForRemoteNotifications()
        
        Messaging.messaging().delegate = self
    }
}

@main
struct CoinAppApp: App {
    @StateObject var userViewModel = UserViewModel()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userViewModel)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    @MainActor
    private func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo
        print("Notification received while app is in foreground: \(userInfo)")
        return [.sound, .badge]
    }
    
    @MainActor
    private func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        print("User interacted with the notification: \(userInfo)")
    }
    
    @MainActor
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any]) -> UIBackgroundFetchResult {
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        print("Received remote notification: \(userInfo)")
        return .newData
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else {
            print("No FCM token received")
            return
        }
        
        print("Firebase registration token: \(fcmToken)")
        
        let dataDict: [String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"),
                                        object: nil,
                                        userInfo: dataDict)
        
        Messaging.messaging().subscribe(toTopic: "main") { error in
            print("Subscribed to main topic")
        }
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}
