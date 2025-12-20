import Foundation

/// Persistent storage for deferred deep link state
final class Storage {
    private let defaults: UserDefaults
    private let checkedKey = "com.dynalinks.deferredDeepLinkChecked"
    private let resultKey = "com.dynalinks.deferredDeepLinkResult"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Whether the deferred deep link check has been performed
    var hasCheckedForDeferredDeepLink: Bool {
        get { defaults.bool(forKey: checkedKey) }
        set { defaults.set(newValue, forKey: checkedKey) }
    }

    /// Cached result from previous check
    var cachedResult: DeepLinkResult? {
        get {
            guard let data = defaults.data(forKey: resultKey) else { return nil }
            do {
                return try JSONDecoder().decode(DeepLinkResult.self, from: data)
            } catch {
                Logger.warning("Failed to decode cached result: \(error)")
                return nil
            }
        }
        set {
            if let newValue = newValue {
                do {
                    let data = try JSONEncoder().encode(newValue)
                    defaults.set(data, forKey: resultKey)
                } catch {
                    Logger.warning("Failed to encode result for caching: \(error)")
                }
            } else {
                defaults.removeObject(forKey: resultKey)
            }
        }
    }

    /// Reset all stored state (useful for testing)
    func reset() {
        hasCheckedForDeferredDeepLink = false
        cachedResult = nil
        Logger.debug("Storage reset")
    }
}
