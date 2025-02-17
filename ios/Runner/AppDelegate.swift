import Flutter
import UIKit
import UserNotifications
import Foundation

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    // Store completion so we can call it once we actually get the token (or error).
    private var tokenCompletion: ((String?) -> Void)?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Set up method channel
        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(
            name: "online.denverbartenders.IamDenverBartender/push",
            binaryMessenger: controller.binaryMessenger
        )
        
        channel.setMethodCallHandler { [weak self] (call, result) in
            if call.method == "getAPNsToken" {
                result(UserDefaults.standard.string(forKey: "APNsToken"))
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
        
        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            print("Permission granted: \(granted)")
        }
        
        // Register for remote notifications
        application.registerForRemoteNotifications()
        
        // Needed for iOS 10+ user notification callbacks
        UNUserNotificationCenter.current().delegate = self
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Store device token when received
    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        UserDefaults.standard.set(token, forKey: "APNsToken")
        print("Device Token: \(token)")
        
        // Call the stored completion so the original Flutter call returns the token
        tokenCompletion?(token)
        tokenCompletion = nil
    }
    
    // Handle registration errors
    override func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error)")
        
        // Return nil (or an error message) to the original Flutter call
        tokenCompletion?(nil)
        tokenCompletion = nil
    }
}

// Example of a Codable struct for JSON parsing
struct ExampleData: Codable {
    let id: Int
    let name: String
}

// Function to parse JSON data
func parseJSON(data: Data) {
    do {
        let decodedData = try JSONDecoder().decode(ExampleData.self, from: data)
        print("ID: \(decodedData.id), Name: \(decodedData.name)")
    } catch {
        print("Failed to decode JSON: \(error)")
    }
}
