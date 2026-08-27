# NotchHUD

A MacBook-notch HUD for your AI agent swarm. Live status (Working / Needs me / Done) for every agentic CLI session (Claude Code, Codex, more), always-on peek, hover-expand glass panel, click-to-focus the exact terminal.

Built Swift 6 / SwiftUI + AppKit, SPM, Command Line Tools only (vendored DynamicNotchKit, macro-patched). See TASKS.md for build state and specs/ for milestone specs.

Build: `swift build` · Test: `swift test` · Bundle: `scripts/make-app.sh` → `build/NotchHUD.app`

## VS Code sessions

Claude Code running as the VS Code extension has no tty anywhere in its process
chain, so the tty-based focus strategies, the row-focusability check, and the
approval bridge all miss it. `VSCodeStrategy` closes that gap: `notch-emit`
records `entrypoint`, `vscodeHostPid` and `workspaceName`, focusability is asked
of `FocusDispatcher.canFocus` instead of `terminal.tty`, and the strategy raises
the window whose title carries the workspace name.

Raising a VS Code window is an accessibility action, so it needs an
**Accessibility** grant (System Settings → Privacy & Security → Accessibility)
on top of the Automation grant the other strategies use.

Two sessions in one VS Code window share a window title, so click-to-focus
raises the window but cannot pick the tab.
