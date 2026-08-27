import Foundation
import Testing
@testable import NotchHUD

private func identity(
    termProgram: String? = nil,
    tty: String? = nil,
    entrypoint: String? = nil,
    workspaceName: String? = nil
) -> TerminalIdentity {
    TerminalIdentity(
        termProgram: termProgram,
        tty: tty,
        itermSessionId: nil,
        weztermPane: nil,
        kittyWindowId: nil,
        windowId: nil,
        entrypoint: entrypoint,
        vscodeHostPid: nil,
        vscodePid: nil,
        workspaceName: workspaceName
    )
}

@Test func vscodeStrategyHandlesExtensionSessionsWithoutTTY() {
    let strategy = VSCodeStrategy()

    #expect(
        strategy.canHandle(
            identity(
                termProgram: "vscode",
                entrypoint: "claude-vscode",
                workspaceName: "marketing-writing-style"
            )
        )
    )
}

@Test func vscodeStrategyHandlesIntegratedTerminalSessions() {
    let strategy = VSCodeStrategy()

    #expect(
        strategy.canHandle(
            identity(termProgram: "vscode", tty: "/dev/ttys012", workspaceName: "notch-hud")
        )
    )
}

@Test func vscodeStrategyIgnoresOtherTerminals() {
    let strategy = VSCodeStrategy()

    #expect(
        !strategy.canHandle(
            identity(termProgram: "Apple_Terminal", tty: "/dev/ttys012", workspaceName: "notch-hud")
        )
    )
    #expect(!strategy.canHandle(identity()))
}

@Test func vscodeStrategyNeedsAWorkspaceNameToMatchAWindowTitle() {
    let strategy = VSCodeStrategy()

    #expect(!strategy.canHandle(identity(termProgram: "vscode", entrypoint: "claude-vscode")))
    #expect(
        !strategy.canHandle(
            identity(termProgram: "vscode", entrypoint: "claude-vscode", workspaceName: "")
        )
    )
}

@Test func terminalIdentityDecodesWithoutTheVSCodeFields() throws {
    let data = Data(
        """
        {"termProgram": "Apple_Terminal", "tty": "/dev/ttys012"}
        """.utf8
    )

    let decoded = try JSONDecoder().decode(TerminalIdentity.self, from: data)

    #expect(decoded.termProgram == "Apple_Terminal")
    #expect(decoded.tty == "/dev/ttys012")
    #expect(decoded.entrypoint == nil)
    #expect(decoded.vscodeHostPid == nil)
    #expect(decoded.workspaceName == nil)
}

@Test func terminalIdentityDecodesTheVSCodeFields() throws {
    let data = Data(
        """
        {
          "termProgram": "vscode",
          "entrypoint": "claude-vscode",
          "vscodeHostPid": "12254",
          "vscodePid": "644",
          "workspaceName": "marketing-writing-style"
        }
        """.utf8
    )

    let decoded = try JSONDecoder().decode(TerminalIdentity.self, from: data)

    #expect(decoded.tty == nil)
    #expect(decoded.entrypoint == "claude-vscode")
    #expect(decoded.vscodeHostPid == "12254")
    #expect(decoded.workspaceName == "marketing-writing-style")
}
