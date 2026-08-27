import Foundation

/// Raises the VS Code window running a session.
///
/// VS Code exposes no useful AppleScript dictionary and no per-window handle we
/// can address directly, so this matches on the window title: VS Code renders
/// `${activeEditorShort} — ${rootName}`, and `rootName` is the basename of the
/// workspace folder — the same value the emitter records as `workspaceName`.
struct VSCodeStrategy: FocusStrategy {
    func canHandle(_ identity: TerminalIdentity) -> Bool {
        guard identity.termProgram == "vscode" || identity.entrypoint == "claude-vscode" else {
            return false
        }

        guard let workspaceName = identity.workspaceName else {
            return false
        }

        return !workspaceName.isEmpty
    }

    func focus(_ identity: TerminalIdentity) throws {
        guard let workspaceName = identity.workspaceName, !workspaceName.isEmpty else {
            throw FocusError.notFound
        }

        let escapedName = workspaceName
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        // Raising a window is an accessibility action, so this needs an
        // Accessibility grant, not just the Automation grant the other
        // strategies use.
        let source = """
        tell application "Visual Studio Code" to activate
        tell application "System Events"
          tell process "Code"
            set target to "\(escapedName)"
            repeat with w in windows
              if (name of w) contains target then
                perform action "AXRaise" of w
                return "ok"
              end if
            end repeat
          end tell
        end tell
        return "notfound"
        """

        if try AppleScriptRunner.run(source) == "notfound" {
            throw FocusError.notFound
        }
    }
}
