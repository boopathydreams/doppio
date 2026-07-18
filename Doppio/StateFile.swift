import Foundation

/// URL schemes can't return data. The app publishes its state to a file
/// the CLI reads for `doppio status`.
enum StateFile {
    static var url: URL {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Doppio", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("state.json")
    }

    static func write(active: Bool, endDate: Date?) {
        let payload: [String: Any] = [
            "active": active,
            "endEpoch": endDate?.timeIntervalSince1970 ?? 0
        ]
        let data = try? JSONSerialization.data(withJSONObject: payload)
        try? data?.write(to: url, options: .atomic)
    }
}
