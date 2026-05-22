import Foundation

// UserDefaults-backed per-station AGC gain cache.
final class GainCache: @unchecked Sendable {
    private static let keyPrefix = "fm.sink.agc.gain."

    func read(stationID: String) -> Float? {
        let value = UserDefaults.standard.float(forKey: Self.keyPrefix + stationID)
        return value > 0 ? value : nil
    }

    func write(stationID: String, gain: Float) {
        UserDefaults.standard.set(gain, forKey: Self.keyPrefix + stationID)
    }
}
