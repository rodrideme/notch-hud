import Foundation

struct AppEnvironment {
    let rootURL: URL
    let configURL: URL
    let spoolURL: URL
    let pendingURL: URL
    let decisionsURL: URL
    let sessionAllowURL: URL
    let workingStaleSeconds: TimeInterval = 90
    /// How long a session stays live before it moves to the history section.
    let liveSeconds: TimeInterval = 900
    /// How long finished work is kept and listed. Beyond this the spool file goes.
    let dropSeconds: TimeInterval = 48 * 60 * 60

    init(fileManager: FileManager = .default) {
        let rootURL = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".notch-hud", isDirectory: true)
        self.rootURL = rootURL
        configURL = rootURL
            .appendingPathComponent("config.json", isDirectory: false)
        spoolURL = rootURL
            .appendingPathComponent("sessions", isDirectory: true)
        pendingURL = rootURL
            .appendingPathComponent("pending", isDirectory: true)
        decisionsURL = rootURL
            .appendingPathComponent("decisions", isDirectory: true)
        sessionAllowURL = rootURL
            .appendingPathComponent("session-allow", isDirectory: true)

        for directoryURL in [spoolURL, pendingURL, decisionsURL, sessionAllowURL] {
            do {
                try fileManager.createDirectory(
                    at: directoryURL,
                    withIntermediateDirectories: true,
                    attributes: [.posixPermissions: NSNumber(value: 0o700)]
                )
                try fileManager.setAttributes(
                    [.posixPermissions: NSNumber(value: 0o700)],
                    ofItemAtPath: directoryURL.path
                )
            } catch {
                NSLog(
                    "NotchHUD could not prepare %@: %@",
                    directoryURL.path,
                    error.localizedDescription
                )
            }
        }
    }
}
