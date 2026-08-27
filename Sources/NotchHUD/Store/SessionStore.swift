import Foundation
import Observation

@Observable
@MainActor
final class SessionStore {
    /// Live sessions. Drives the peek count and the top of the panel.
    private(set) var sessions: [Session] = []
    /// Finished work from the retention window, newest first, one row per
    /// session showing the last thing it did.
    private(set) var recentSessions: [Session] = []
    private var sourceSessions: [Session] = []
    private var pendingSessionIDs = Set<String>()
    private let liveSeconds: TimeInterval
    private let clock: @Sendable () -> Date

    init(liveSeconds: TimeInterval = 15 * 60, clock: @escaping @Sendable () -> Date = Date.init) {
        self.liveSeconds = liveSeconds
        self.clock = clock
    }

    func apply(_ sessions: [Session]) {
        sourceSessions = sessions
        rebuildSessions()
    }

    func markPendingApprovals(sessionIDs: Set<String>) {
        pendingSessionIDs = Set(sessionIDs.flatMap { sessionID in
            [sessionID, "claude-\(sessionID)"]
        })
        rebuildSessions()
    }

    var sessionsWithoutPendingOverlay: [Session] {
        sourceSessions
    }

    private func rebuildSessions() {
        let now = clock()
        let overlaid = sourceSessions.map { session -> Session in
            var session = session
            if pendingSessionIDs.contains(session.id) {
                session.status = .needs_me
            }
            return session
        }

        // A pending approval always reads as live, however long it has waited.
        let (history, live) = overlaid.stablePartition { session in
            !pendingSessionIDs.contains(session.id)
                && session.isHistory(at: now, liveSeconds: liveSeconds)
        }

        recentSessions = history.sorted { lhs, rhs in
            if lhs.updatedAt != rhs.updatedAt {
                return lhs.updatedAt > rhs.updatedAt
            }
            return lhs.id < rhs.id
        }

        sessions = live.sorted { lhs, rhs in
            let lhsRank = Self.sortRank(for: lhs.displayStatus)
            let rhsRank = Self.sortRank(for: rhs.displayStatus)

            if lhsRank != rhsRank {
                return lhsRank < rhsRank
            }
            if lhs.hasKnownWindow != rhs.hasKnownWindow {
                return lhs.hasKnownWindow
            }
            if lhs.updatedAt != rhs.updatedAt {
                return lhs.updatedAt > rhs.updatedAt
            }
            return lhs.id < rhs.id
        }
    }

    var counts: (working: Int, needsMe: Int, done: Int) {
        var working = 0
        var needsMe = 0
        var done = 0

        for session in sessions {
            switch session.displayStatus {
            case .working:
                working += 1
            case .needsMe:
                needsMe += 1
            case .done:
                done += 1
            case .idle:
                break
            }
        }

        return (working, needsMe, done)
    }

    var total: Int {
        sessions.count
    }

    private static func sortRank(for status: DisplayStatus) -> Int {
        switch status {
        case .needsMe:
            0
        case .working:
            1
        case .done:
            2
        case .idle:
            3
        }
    }
}

private extension Array {
    /// Splits into (matching, rest) while preserving order in both halves.
    func stablePartition(by isMatch: (Element) -> Bool) -> ([Element], [Element]) {
        var matching: [Element] = []
        var rest: [Element] = []

        for element in self {
            if isMatch(element) {
                matching.append(element)
            } else {
                rest.append(element)
            }
        }

        return (matching, rest)
    }
}
