import Foundation
import Testing
@testable import NotchHUD

private let now = Date(timeIntervalSince1970: 1_800_000_000)

private func vscodeIdentity(workspaceName: String = "marketing-writing-style") -> TerminalIdentity {
    TerminalIdentity(
        termProgram: "vscode",
        tty: nil,
        itermSessionId: nil,
        weztermPane: nil,
        kittyWindowId: nil,
        windowId: nil,
        entrypoint: "claude-vscode",
        vscodeHostPid: "12254",
        vscodePid: "644",
        workspaceName: workspaceName
    )
}

private func session(
    id: String = "claude-abc",
    agent: String = "claude-code",
    status: SessionStatus,
    secondsAgo: TimeInterval = 0,
    terminal: TerminalIdentity? = vscodeIdentity()
) -> Session {
    let envelope = SessionEnvelope(
        schema: 1,
        id: id,
        agent: agent,
        project: "marketing-writing-style",
        status: status,
        task: "Build the notch HUD",
        updated: "2026-08-27T13:00:00Z",
        seq: 1,
        terminal: terminal
    )
    return Session(envelope: envelope, updatedAt: now.addingTimeInterval(-secondsAgo))
}

// MARK: - history classification

@Test func aLiveSessionIsNotHistory() {
    #expect(!session(status: .working, secondsAgo: 30).isHistory(at: now, liveSeconds: 900))
    #expect(!session(status: .done, secondsAgo: 30).isHistory(at: now, liveSeconds: 900))
}

@Test func aQuietSessionBecomesHistory() {
    #expect(session(status: .done, secondsAgo: 1_000).isHistory(at: now, liveSeconds: 900))
}

@Test func aClosedSessionIsHistoryImmediately() {
    #expect(session(status: .ended, secondsAgo: 5).isHistory(at: now, liveSeconds: 900))
}

@Test func endedRendersAsDone() {
    #expect(SessionStatus.ended.displayStatus == .done)
}

// MARK: - store split

@Test @MainActor func storeSplitsLiveSessionsFromFinishedWork() {
    let store = SessionStore(liveSeconds: 900, clock: { now })
    store.apply([
        session(id: "claude-live", status: .working, secondsAgo: 10),
        session(id: "claude-closed", status: .ended, secondsAgo: 20),
        session(id: "claude-quiet", status: .done, secondsAgo: 5_000)
    ])

    #expect(store.sessions.map(\.id) == ["claude-live"])
    #expect(Set(store.recentSessions.map(\.id)) == ["claude-closed", "claude-quiet"])
    // The peek count must stay live-only so two days of history cannot inflate it.
    #expect(store.total == 1)
}

@Test @MainActor func recentSessionsAreNewestFirst() {
    let store = SessionStore(liveSeconds: 900, clock: { now })
    store.apply([
        session(id: "claude-older", status: .ended, secondsAgo: 5_000),
        session(id: "claude-newer", status: .ended, secondsAgo: 100)
    ])

    #expect(store.recentSessions.map(\.id) == ["claude-newer", "claude-older"])
}

@Test @MainActor func aPendingApprovalKeepsASessionLiveHoweverLongItHasWaited() {
    let store = SessionStore(liveSeconds: 900, clock: { now })
    store.apply([session(id: "claude-abc", status: .done, secondsAgo: 10_000)])
    store.markPendingApprovals(sessionIDs: ["abc"])

    #expect(store.sessions.map(\.id) == ["claude-abc"])
    #expect(store.recentSessions.isEmpty)
}

// MARK: - resume

@Test func resumeURLCarriesTheRawSessionID() throws {
    let url = try #require(SessionResumer.resumeURL(for: session(id: "claude-abc", status: .ended)))

    #expect(url.scheme == "vscode")
    #expect(url.host == "anthropic.claude-code")
    #expect(url.path == "/open")
    #expect(url.query == "session=abc")
}

@Test func resumeIsOnlyOfferedForVSCodeClaudeSessions() {
    let terminalIdentity = TerminalIdentity(
        termProgram: "Apple_Terminal",
        tty: "/dev/ttys012",
        itermSessionId: nil,
        weztermPane: nil,
        kittyWindowId: nil,
        windowId: nil,
        entrypoint: nil,
        vscodeHostPid: nil,
        vscodePid: nil,
        workspaceName: "notch-hud"
    )

    #expect(!SessionResumer.canResume(session(status: .ended, terminal: terminalIdentity)))
    #expect(!SessionResumer.canResume(session(status: .ended, terminal: nil)))
    // A Codex session has no Claude conversation to reopen.
    #expect(!SessionResumer.canResume(session(id: "codex-1", agent: "codex", status: .ended)))
}
