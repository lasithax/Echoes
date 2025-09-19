import Foundation
import UserNotifications

/// Handles local notifications and its state and Also captures which memory notification the user tapped so the app can open it.
final class NotificationsManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
	@Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
	@Published var tappedMemoryId: String?
	
	/// Sets the UNUserNotificationCenter delegate and syncs current permission state.
	func configure() {
		UNUserNotificationCenter.current().delegate = self
		refreshAuthorizationStatus()
	}
	
	/// Refreshes authorizationStatus.
	func refreshAuthorizationStatus() {
		UNUserNotificationCenter.current().getNotificationSettings { settings in
			DispatchQueue.main.async {
				self.authorizationStatus = settings.authorizationStatus
			}
		}
	}
	
	/// Asks the user for permission to show alerts/sounds/badges.
	func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
		UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
			DispatchQueue.main.async {
				self.refreshAuthorizationStatus()
				completion?(granted)
			}
		}
	}
	
	/// Shows an immediate local notification about a memory being available.
	func scheduleMemoryUnlockedNotification(id: String, title: String, body: String) {
		let content = UNMutableNotificationContent()
		content.title = title
		content.body = body
		content.sound = .default
		content.userInfo = ["memoryId": id]
		
		let request = UNNotificationRequest(identifier: "memory_unlocked_\(id)", content: content, trigger: nil)
		UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
	}
	
	/// Present notifications as banner and sound while the app is in foreground.
	func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
		completionHandler([.banner, .sound])
	}
	
	/// Capture the memory id from the notification so the app can navigate to it.
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		let info = response.notification.request.content.userInfo
		if let memoryId = info["memoryId"] as? String {
			DispatchQueue.main.async {
				self.tappedMemoryId = memoryId
			}
		}
		completionHandler()
	}
}
