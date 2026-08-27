import AppKit
import Foundation

/// Reopens a finished Claude Code session.
///
/// The VS Code extension registers a URI handler whose `/open` route forwards
/// its `session` query item to the `claude-vscode.primaryEditor.open` command,
/// so a `vscode://` URL is enough to pick a conversation back up. VS Code routes
/// the URL to its frontmost window, which is why the caller raises the target
/// window first.
enum SessionResumer {
    static let extensionIdentifier = "anthropic.claude-code"

    static func resumeURL(for session: Session) -> URL? {
        guard let terminal = session.terminal,
              terminal.entrypoint == "claude-vscode" || terminal.termProgram == "vscode",
              let sessionID = session.claudeSessionID,
              var components = URLComponents(string: "vscode://\(extensionIdentifier)/open")
        else {
            return nil
        }

        components.queryItems = [URLQueryItem(name: "session", value: sessionID)]
        return components.url
    }

    static func canResume(_ session: Session) -> Bool {
        resumeURL(for: session) != nil
    }

    @MainActor
    @discardableResult
    static func resume(_ session: Session) -> Bool {
        guard let url = resumeURL(for: session) else {
            return false
        }

        return NSWorkspace.shared.open(url)
    }
}
