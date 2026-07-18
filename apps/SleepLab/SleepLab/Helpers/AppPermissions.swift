import AVFoundation
import CoreLocation
import Foundation
import UserNotifications

/// Demandes d’autorisations système avec explications (onboarding).
enum AppPermissions {

    enum MicrophonePermissionStatus {
        case granted
        case denied
        case undetermined
    }

    @MainActor
    static func notificationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func requestNotifications() async -> Bool {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    static func microphoneStatus() -> MicrophonePermissionStatus {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted: return .granted
            case .denied: return .denied
            case .undetermined: return .undetermined
            @unknown default: return .undetermined
            }
        }
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted: return .granted
        case .denied: return .denied
        case .undetermined: return .undetermined
        @unknown default: return .undetermined
        }
    }

    static func requestMicrophone() async -> Bool {
        if #available(iOS 17.0, *) {
            return await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    @MainActor
    static func locationStatus() -> CLAuthorizationStatus {
        CLLocationManager().authorizationStatus
    }

    @MainActor
    static func requestLocationWhenInUse() {
        let manager = CLLocationManager()
        manager.requestWhenInUseAuthorization()
    }
}
