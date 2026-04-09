import Foundation

// ═══════════════════════════════════════════════════════
// MARK: - CLI Install Checker
// ═══════════════════════════════════════════════════════

public final class CLIInstallChecker {
    private let executableName: String
    private let knownExecutablePaths: [String]
    private let installHint: String
    /// 실행 파일이 실제로 우리가 원하는 AI 도구인지 검증하는 클로저.
    /// `(path, versionOutput)` 를 받아서 맞으면 `true` 반환.
    private let identityValidator: (String, String) -> Bool
    private let lock = NSLock()
    private var _isInstalled = false
    private var _version = ""
    private var _path = ""
    private var _errorInfo = ""
    private var lastCheckedAt: Date?
    private let cacheTTL: TimeInterval = 30

    public init(
        executableName: String,
        knownExecutablePaths: [String],
        installHint: String,
        identityValidator: @escaping (String, String) -> Bool = { _, _ in true }
    ) {
        self.executableName = executableName
        self.knownExecutablePaths = knownExecutablePaths
        self.installHint = installHint
        self.identityValidator = identityValidator
    }

    public var isInstalled: Bool { lock.lock(); defer { lock.unlock() }; return _isInstalled }
    public var version: String { lock.lock(); defer { lock.unlock() }; return _version }
    public var path: String { lock.lock(); defer { lock.unlock() }; return _path }
    public var errorInfo: String { lock.lock(); defer { lock.unlock() }; return _errorInfo }

    public func check(force: Bool = false) {
        // 캐시 유효성만 lock 안에서 확인하고, 실제 셸 실행은 lock 밖에서 수행.
        // shellSync()는 서브프로세스를 실행하여 3초+ 블로킹될 수 있으므로
        // lock을 보유한 채 실행하면 다른 스레드에서 isInstalled/path 등을 읽을 때
        // 불필요한 lock contention이 발생합니다.
        lock.lock()
        if !force,
           let lastCheckedAt,
           Date().timeIntervalSince(lastCheckedAt) < cacheTTL {
            lock.unlock()
            return
        }
        lastCheckedAt = Date()
        let exe = executableName
        let knownPaths = knownExecutablePaths
        let hint = installHint
        let validate = identityValidator
        lock.unlock()

        // 1) Try `which <cli>` with our enriched PATH
        if let p = TerminalTab.shellSync("which \(exe) 2>/dev/null")?.trimmingCharacters(in: .whitespacesAndNewlines), !p.isEmpty {
            if let ver = verifyAndGetVersion(path: p, validate: validate) {
                lock.lock()
                _isInstalled = true; _path = p; _errorInfo = ""; _version = ver
                lock.unlock()
                return
            }
        }

        // 2) Check well-known installation paths directly
        let allPATHDirs = TerminalTab.buildFullPATH().split(separator: ":").map(String.init)
        let allCandidates = knownPaths + allPATHDirs.map { $0 + "/\(exe)" }

        for candidate in allCandidates {
            if FileManager.default.isExecutableFile(atPath: candidate) {
                if let ver = verifyAndGetVersion(path: candidate, validate: validate) {
                    lock.lock()
                    _isInstalled = true; _path = candidate; _errorInfo = ""; _version = ver
                    lock.unlock()
                    return
                }
            }
        }

        // 3) Fallback: try login shell with timeout (prevents hang)
        if let p = TerminalTab.shellSyncLoginWithTimeout("which \(exe) 2>/dev/null", timeout: 3)?.trimmingCharacters(in: .whitespacesAndNewlines), !p.isEmpty {
            if let ver = verifyAndGetVersion(path: p, validate: validate, useLoginShell: true) {
                lock.lock()
                _isInstalled = true; _path = p; _errorInfo = ""; _version = ver
                lock.unlock()
                return
            }
        }

        // Not found
        lock.lock()
        _isInstalled = false
        _version = ""
        _path = ""
        _errorInfo = hint
        lock.unlock()
    }

    // MARK: - Identity Verification

    /// 실행 파일의 --version 출력을 가져오고 identityValidator로 검증.
    /// 검증 통과 시 버전 문자열 반환, 실패 시 nil.
    private func verifyAndGetVersion(
        path: String,
        validate: (String, String) -> Bool,
        useLoginShell: Bool = false
    ) -> String? {
        let cmd = "\"\(path)\" --version 2>/dev/null"
        let ver: String
        if useLoginShell {
            ver = TerminalTab.shellSyncLoginWithTimeout(cmd, timeout: 3)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } else {
            ver = TerminalTab.shellSync(cmd)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }

        // validator가 (path, version) 조합으로 진짜 도구인지 확인
        guard validate(path, ver) else { return nil }
        return ver
    }
}

// ═══════════════════════════════════════════════════════
// MARK: - Shared Checkers (Singleton per Provider)
// ═══════════════════════════════════════════════════════

public enum ClaudeInstallChecker {
    public static let shared = CLIInstallChecker(
        executableName: "claude",
        knownExecutablePaths: [
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude",
            NSHomeDirectory() + "/.npm-global/bin/claude",
        ],
        installHint: "Claude CLI not found. Install with: \(AgentProvider.claude.installCommand)",
        identityValidator: { path, version in
            // "Claude Code"가 --version 출력에 포함되면 확정
            if version.localizedCaseInsensitiveContains("claude") { return true }
            // npm 글로벌/node_modules 경로면 높은 확률로 Claude Code
            if path.contains("node_modules") || path.contains(".npm") { return true }
            // --help 출력으로 2차 확인 (brew 동명 패키지 배제)
            let help = TerminalTab.shellSync("\"\(path)\" --help 2>/dev/null")?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return help.localizedCaseInsensitiveContains("claude code")
        }
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
        installHint: "Codex CLI not found. Install Codex Desktop or add the codex binary to PATH.",
        identityValidator: { path, version in
            // Codex Desktop 앱 번들 내부 바이너리
            if path.contains("Codex.app") { return true }
            // npm 경로
            if path.contains("node_modules") || path.contains(".npm") { return true }
            // --help에 "openai" 또는 "codex exec" 포함 시 확정
            let help = TerminalTab.shellSync("\"\(path)\" --help 2>/dev/null")?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if help.localizedCaseInsensitiveContains("openai") { return true }
            if help.contains("codex exec") || help.contains("codex chat") { return true }
            // --version 출력이 semver 패턴이고 위 경로에서 온 경우
            return false
        }
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
        installHint: "Gemini CLI not found. Install with: \(AgentProvider.gemini.installCommand)",
        identityValidator: { path, version in
            // npm 경로면 높은 확률로 @google/gemini-cli
            if path.contains("node_modules") || path.contains(".npm") { return true }
            // --help에 "Gemini CLI" 포함 시 확정 (brew gemini-repl 등과 구분)
            let help = TerminalTab.shellSync("\"\(path)\" --help 2>/dev/null")?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if help.localizedCaseInsensitiveContains("gemini cli") { return true }
            if help.contains("--prompt") && help.contains("google") { return true }
            return false
        }
    )
}
