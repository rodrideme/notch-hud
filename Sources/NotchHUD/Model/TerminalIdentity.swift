struct TerminalIdentity: Codable, Sendable {
    let termProgram: String?
    let tty: String?
    let itermSessionId: String?
    let weztermPane: String?
    let kittyWindowId: String?
    let windowId: String?
    /// Claude Code's CLAUDE_CODE_ENTRYPOINT. "claude-vscode" means the VS Code
    /// extension, which has no tty anywhere in its process chain.
    let entrypoint: String?
    /// PID of the per-window VS Code extension host. Distinguishes windows;
    /// vscodePid does not.
    let vscodeHostPid: String?
    /// PID of the shared VS Code Electron main process. Same for every window.
    let vscodePid: String?
    /// Basename of the workspace folder, which VS Code puts in the window title.
    let workspaceName: String?
}
