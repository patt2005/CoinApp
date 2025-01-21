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
import SuperwallKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: AppConstants.revenueCatApiKey)
        
        FirebaseApp.configure()
        
        UNUserNotificationCenter.current().delegate = self
        
        Task {
            await handleNotificationPermissions(application: application)
            await AppConstants.getApiKey()
        }
        
        Superwall.configure(apiKey: AppConstants.superWallApiKey, purchaseController: purchaseController)
        
        purchaseController.syncSubscriptionStatus()
        
        return true
    }
    
    @MainActor
    private func handleNotificationPermissions(application: UIApplication) async {
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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
    -> UNNotificationPresentationOptions {
        return [[.badge, .sound]]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        
        let coin = Coin(fromNotificationData: userInfo)
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        AppProvider.shared.path.append(.coinDetail(coin: coin))
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else {
            print("No FCM token received")
            return
        }
        
        UserApi.shared.userId = fcmToken
        
        if (AppProvider.shared.showOnboarding) {
            Task {
                do {
                    try await UserApi.shared.registerUser(withId: fcmToken)
                    
                    print("User was registered!")
                } catch {
                    print("There was an error registering the user: \(error.localizedDescription)")
                }
            }
        }
        
        let dataDict: [String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"),
                                        object: nil,
                                        userInfo: dataDict)
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}
