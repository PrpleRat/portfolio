import CryptoKit
import Foundation

actor PINService {

    static let shared = PINService()
    private let defaults = UserDefaults.standard

    private var failedAttempts: Int = 0
    private var lockoutUntil: Date?

    func setPIN(_ pin: String) {
        let salt = generateSalt()
        let hash = hashPIN(pin, salt: salt)
        defaults.set(hash, forKey: AppConstants.pinHashKey)
        defaults.set(salt, forKey: AppConstants.pinSaltKey)
    }

    func verifyPIN(_ pin: String) -> Bool {
        guard
            let storedHash = defaults.string(forKey: AppConstants.pinHashKey),
            let salt = defaults.string(forKey: AppConstants.pinSaltKey)
        else { return false }

        return hashPIN(pin, salt: salt) == storedHash
    }

    var hasPIN: Bool {
        defaults.string(forKey: AppConstants.pinHashKey) != nil
    }

    func clearPIN() {
        defaults.removeObject(forKey: AppConstants.pinHashKey)
        defaults.removeObject(forKey: AppConstants.pinSaltKey)
    }

    var isLockedOut: Bool {
        guard let until = lockoutUntil else { return false }
        return Date() < until
    }

    var lockoutTimeRemaining: TimeInterval {
        guard let until = lockoutUntil else { return 0 }
        return max(0, until.timeIntervalSinceNow)
    }

    func recordFailedAttempt() {
        failedAttempts += 1
        if failedAttempts >= AppConstants.maxPINAttempts {
            lockoutUntil = Date().addingTimeInterval(AppConstants.pinLockoutDuration)
            failedAttempts = 0
        }
    }

    func resetAttempts() {
        failedAttempts = 0
        lockoutUntil = nil
    }

    func setCustomQuestion(_ question: String, answer: String) {
        let salt = generateSalt()
        defaults.set(question, forKey: AppConstants.questionKey)
        defaults.set(hashPIN(answer.lowercased(), salt: salt), forKey: AppConstants.answerHashKey)
        defaults.set(salt, forKey: AppConstants.pinSaltKey + ".answer")
    }

    func verifyAnswer(_ answer: String) -> Bool {
        guard
            let storedHash = defaults.string(forKey: AppConstants.answerHashKey),
            let salt = defaults.string(forKey: AppConstants.pinSaltKey + ".answer")
        else { return false }
        return hashPIN(answer.lowercased(), salt: salt) == storedHash
    }

    var customQuestion: String? {
        defaults.string(forKey: AppConstants.questionKey)
    }

    private func hashPIN(_ pin: String, salt: String) -> String {
        let combined = "\(pin):\(salt)"
        let data = Data(combined.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func generateSalt() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }
}
