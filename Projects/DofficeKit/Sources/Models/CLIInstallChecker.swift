import Foundation

// ═══════════════════════════════════════════════════════
// MARK: - CLI Install Checker
// ═══════════════════════════════════════════════════════

public final class CLIInstallChecker {
    private let executableName: String
    private let knownExecutablePaths: [String]
    private let installHint: String
    private let lock = NSLock()
    private var _isInstalled = false
    private var _version = ""
    private var _path = ""
    private var _errorInfo = ""
    private var lastCheckedAt: Date?
    private let cacheTTL: TimeInterval = 10

    public init(executableName: String, knownExecutablePaths: [String], installHint: String) {
        self.executableName = executableName
        self.knownExecutablePaths = knownExecutablePaths
        self.installHint = installHint
    }

    public var isInstalled: Bool { lock.lock(); defer { lock.unlock() }; return _isInstalled }
    public var version: String { lock.lock(); defer { lock.unlock() }; return _version }
    public var path: String { lock.lock(); defer { lock.unlock() }; return _path }
    public var errorInfo: String { lock.lock(); defer { lock.unlock() }; return _errorInfo }

    public func check(force: Bool = false) {
        lock.lock()
        defer { lock.unlock() }

        if !force,
           let lastCheckedAt,
           Date().timeIntervalSince(lastCheckedAt) < cacheTTL {
            return
        }

        lastCheckedAt = Date()

        // 1) Try `which <cli>` with our enriched PATH
        if let p = TerminalTab.shellSync("which \(executableName) 2>/dev/null")?.trimmingCharacters(in: .whitespacesAndNewlines), !p.isEmpty {
            _isInstalled = true; _path = p; _errorInfo = ""
            _version = TerminalTab.shellSync("\(executableName) --version 2>/dev/null")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return
        }

        // 2) Check well-known installation paths directly
        let allPATHDirs = TerminalTab.buildFullPATH().split(separator: ":").map(String.init)
        let allCandidates = knownExecutablePaths + allPATHDirs.map { $0 + "/\(executableName)" }

        for candidate in allCandidates {
            if FileManager.default.isExecutableFile(atPath: candidate) {
                _isInstalled = true; _path = candidate; _errorInfo = ""
                _version = TerminalTab.shellSync("\"\(candidate)\" --version 2>/dev/null")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return
            }
        }

        // 3) Fallback: try login shell with timeout (prevents hang)
        if let p = TerminalTab.shellSyncLoginWithTimeout("which \(executableName) 2>/dev/null", timeout: 3)?.trimmingCharacters(in: .whitespacesAndNewlines), !p.isEmpty {
            _isInstalled = true; _path = p; _errorInfo = ""
            _version = TerminalTab.shellSyncLoginWithTimeout("\"\(p)\" --version 2>/dev/null", timeout: 3)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return
        }

        // Not found
        _isInstalled = false
        _version = ""
        _path = ""
        _errorInfo = installHint
    }
}

public enum ClaudeInstallChecker {
    public static let shared = CLIInstallChecker(
        executableName: "claude",
        knownExecutablePaths: [
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude",
            NSHomeDirectory() + "/.npm-global/bin/claude",
        ],
        installHint: "Claude CLI not found. Install with: npm install -g @anthropic-ai/claude-code"
    )
}

public enum CodexInstallChecker {
    public static let shared = CLIInstallChecker(
        executableName: "codex",
        knownExecutablePaths: [
            "/Applications/Codex.app/Contents/Resources/codex",
            "/usr/local/bin/codex",
            "/opt/homebrew/bin/codex",
            NSHomeDirectory() + "/.npm-global/bin/codex",
        ],
        installHint: "Codex CLI not found. Install Codex Desktop or add the codex binary to PATH."
    )
}

public enum GeminiInstallChecker {
    public static let shared = CLIInstallChecker(
        executableName: "gemini",
        knownExecutablePaths: [
            "/usr/local/bin/gemini",
            "/opt/homebrew/bin/gemini",
            NSHomeDirectory() + "/.npm-global/bin/gemini",
            NSHomeDirectory() + "/.local/bin/gemini",
        ],
        installHint: "Gemini CLI not found. Install with: npm install -g @anthropic-ai/gemini-cli"
    )
}
