import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    // Store completion so we can call it once we actually get the token (or error).
    private var tokenCompletion: ((String?) -> Void)?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Standard Flutter setup
        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(
            name: "com.example.bartenderCompanion/push",
            binaryMessenger: controller.binaryMessenger
        )
        
        // Handle method calls from Flutter
        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            
            switch call.method {
            case "getAPNsToken":
                // Kick off push-notification registration
                self.registerForPushNotifications { token in
                    // This completion is called once we have a token or a refusal
                    result(token)  // token could be nil if denied or error
                }
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        // Needed for iOS 10+ user notification callbacks
        UNUserNotificationCenter.current().delegate = self
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func registerForPushNotifications(completion: @escaping (String?) -> Void) {
        // Save the completion block so we can call it later when iOS gives us the token.
        self.tokenCompletion = completion
        
        // Ask the user for permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            [weak self] granted, error in
            guard let self = self else { return }
            
            print("Push notification permission granted? \(granted)")
            
            if !granted || error != nil {
                // Permission denied or an error occurred
                DispatchQueue.main.async {
                    // Return nil to Flutter
                    completion(nil)
                }
                self.tokenCompletion = nil
                return
            }
            
            // If granted, check settings
            self.getNotificationSettings()
        }
    }
    
    private func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            
            // If not authorized, return nil
            if settings.authorizationStatus != .authorized {
                DispatchQueue.main.async {
                    self.tokenCompletion?(nil)
                    self.tokenCompletion = nil
                }
                return
            }
            
            // At this point, permission is authorized, so request a real APNs token
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        print("============= APNs TOKEN =============")
        print(token)
        print("======================================")
        
        // Optionally store in UserDefaults or elsewhere
        UserDefaults.standard.set(token, forKey: "APNsToken")
        
        // Call the stored completion so the original Flutter call returns the token
        tokenCompletion?(token)
        tokenCompletion = nil
    }
    
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
