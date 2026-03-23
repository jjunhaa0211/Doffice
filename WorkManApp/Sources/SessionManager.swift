import SwiftUI

class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published var tabs: [TerminalTab] = []
    @Published var activeTabId: String?
    @Published var showNewTabSheet: Bool = false
    @Published var groups: [SessionGroup] = []
    @Published var selectedGroupPath: String? = nil  // nil = 전체 보기
    @Published var focusSingleTab: Bool = false       // 개별 워커 포커스

    var totalTokensUsed: Int {
        tabs.reduce(0) { $0 + $1.tokensUsed }
    }

    // 현재 선택된 그룹의 탭들 (nil이면 전체)
    var visibleTabs: [TerminalTab] {
        guard let path = selectedGroupPath else { return tabs }
        return tabs.filter { $0.projectPath == path }
    }

    let workerNames = ["Pixel", "Byte", "Code", "Bug", "Chip", "Kit", "Dot", "Rex"]

    private var workerIndex = 0
    private var scanTimer: Timer?
    private var saveTickCount = 0

    var activeTab: TerminalTab? {
        tabs.first(where: { $0.id == activeTabId })
    }

    // 프로젝트 경로별 그룹 (순서 유지)
    struct ProjectGroup: Identifiable {
        let id: String // projectPath
        let projectName: String
        let tabs: [TerminalTab]
        var hasActiveTab: Bool
    }

    var projectGroups: [ProjectGroup] {
        var dict: [String: [TerminalTab]] = [:]
        var order: [String] = []
        for tab in tabs {
            if dict[tab.projectPath] == nil { order.append(tab.projectPath) }
            dict[tab.projectPath, default: []].append(tab)
        }
        return order.compactMap { path in
            guard let tabs = dict[path], let first = tabs.first else { return nil }
            return ProjectGroup(
                id: path,
                projectName: first.projectName,
                tabs: tabs,
                hasActiveTab: tabs.contains(where: { $0.id == activeTabId })
            )
        }
    }

    // MARK: - Auto Detect on Launch

    /// Scans for running terminal sessions and Claude Code processes,
    /// auto-creates tabs for each unique project found.
    func autoDetectAndConnect() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let detected = self?.scanRunningTerminals() ?? []

            DispatchQueue.main.async {
                guard let self = self else { return }

                if detected.isEmpty { return }

                // 같은 프로젝트에 몇 개 세션이 붙어있는지 카운트
                var projectSessionCount: [String: Int] = [:]
                for session in detected {
                    projectSessionCount[session.path, default: 0] += 1
                }

                for session in detected {
                    if self.tabs.contains(where: { $0.projectPath == session.path }) {
                        // 이미 있으면 세션 수만 업데이트
                        if let tab = self.tabs.first(where: { $0.projectPath == session.path }) {
                            tab.sessionCount = projectSessionCount[session.path] ?? 1
                        }
                        continue
                    }
                    self.addTab(
                        projectName: session.projectName,
                        projectPath: session.path,
                        isClaude: session.isClaude,
                        detectedPid: session.pid,
                        sessionCount: projectSessionCount[session.path] ?? 1,
                        branch: session.branch
                    )
                }

                if let claudeTab = self.tabs.first(where: { $0.isClaude }) {
                    self.activeTabId = claudeTab.id
                } else {
                    self.activeTabId = self.tabs.first?.id
                }
            }
        }

        // 5초마다 리스캔 + git 정보 갱신 + 주기적 저장
        scanTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.rescanForNewSessions()
            self?.tabs.forEach { $0.refreshGitInfo() }
            // 업적 체크
            if let tabs = self?.tabs {
                AchievementManager.shared.checkSessionAchievements(tabs: tabs)
            }
            // 30초마다 세션 저장 (6번째 tick마다)
            self?.saveTickCount += 1
            if (self?.saveTickCount ?? 0) % 6 == 0 {
                self?.saveSessions()
            }
        }

        // 최초 git 정보 로드
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.tabs.forEach { $0.refreshGitInfo() }
        }
    }

    // MARK: - Detected Session Info

    struct DetectedSession {
        let pid: Int
        let path: String
        let projectName: String
        let branch: String?
        let isClaude: Bool
        let parentApp: String? // Terminal.app, iTerm2, etc.
    }

    // MARK: - Process Scanning

    private func scanRunningTerminals() -> [DetectedSession] {
        var results: [DetectedSession] = []
        var seenPaths = Set<String>()

        // Claude Code 세션만 감지 (진짜 터미널에 붙어있는 것만)
        let claudeSessions = findClaudeCodeSessions()
        for session in claudeSessions {
            if !seenPaths.contains(session.path) {
                seenPaths.insert(session.path)
                results.append(session)
            }
        }

        return results
    }

    private func findClaudeCodeSessions() -> [DetectedSession] {
        var results: [DetectedSession] = []

        // 진짜 터미널(ttys*)에 붙어있는 claude 프로세스만 찾기
        // tty가 ??인 것은 WorkManApp이 spawn한 자식 프로세스이므로 제외
        guard let output = shell("""
            ps -eo pid,tty,args 2>/dev/null \
            | grep -E 'claude\\s+--' \
            | grep -v grep \
            | grep -v Claude.app \
            | grep 'ttys'
            """) else {
            return results
        }

        for line in output.components(separatedBy: "\n") where !line.isEmpty {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let cols = trimmed.split(separator: " ", maxSplits: 2)
            guard cols.count >= 2, let pid = Int(cols[0]) else { continue }

            if let projectPath = getClaudeProjectPath(pid: pid) {
                let projectName = getProjectName(path: projectPath)
                let branch = getBranch(path: projectPath)

                results.append(DetectedSession(
                    pid: pid,
                    path: projectPath,
                    projectName: projectName,
                    branch: branch,
                    isClaude: true,
                    parentApp: getTerminalApp(pid: pid)
                ))
            }
        }

        return results
    }

    /// Claude Code의 lsof 출력에서 프로젝트 경로를 추출
    private func getClaudeProjectPath(pid: Int) -> String? {
        let home = NSHomeDirectory()

        // Strategy A: lsof에서 열린 파일 중 프로젝트 경로 추출
        if let output = shell("lsof -p \(pid) -Fn 2>/dev/null | grep '^n/Users/' | grep -v '/Library/' | grep -v '/.claude/' | grep -v '/tmp/' | grep -v '/var/' | grep -v '/node_modules/' | head -10") {

            for line in output.components(separatedBy: "\n") {
                var path = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if path.hasPrefix("n") { path = String(path.dropFirst()) }
                guard !path.isEmpty, path != "/", path != home else { continue }

                // 파일이면 디렉토리로
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), !isDir.boolValue {
                    path = (path as NSString).deletingLastPathComponent
                }
                guard path != home else { continue }

                // git root 시도
                if let repoRoot = shell("git -C \"\(path)\" rev-parse --show-toplevel 2>/dev/null")?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                   !repoRoot.isEmpty, repoRoot != home {
                    return repoRoot
                }

                return path
            }
        }

        // Strategy B: Claude의 parent shell의 parent가 어디서 실행됐는지 확인
        var current = pid
        for _ in 0..<5 {
            guard let ppidStr = shell("ps -p \(current) -o ppid= 2>/dev/null")?.trimmingCharacters(in: .whitespaces),
                  let ppid = Int(ppidStr), ppid > 1 else { break }

            // parent의 열린 파일 확인
            if let parentFiles = shell("lsof -p \(ppid) -Fn 2>/dev/null | grep '^n/Users/' | grep -v Library | grep -v '.claude' | head -3") {
                for line in parentFiles.components(separatedBy: "\n") {
                    var path = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if path.hasPrefix("n") { path = String(path.dropFirst()) }
                    guard !path.isEmpty, path != "/", path != home else { continue }

                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), !isDir.boolValue {
                        path = (path as NSString).deletingLastPathComponent
                    }
                    guard path != home else { continue }

                    if let repoRoot = shell("git -C \"\(path)\" rev-parse --show-toplevel 2>/dev/null")?
                        .trimmingCharacters(in: .whitespacesAndNewlines),
                       !repoRoot.isEmpty, repoRoot != home {
                        return repoRoot
                    }
                    return path
                }
            }
            current = ppid
        }

        // Strategy C: claude-*-cwd 임시 파일
        if let cwdFiles = shell("find /var/folders -name 'claude-*-cwd' -newer /var/folders 2>/dev/null | head -10") {
            for cwdFile in cwdFiles.components(separatedBy: "\n") where !cwdFile.isEmpty {
                if let content = shell("cat \"\(cwdFile)\" 2>/dev/null")?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                   !content.isEmpty, content != home, content != "/" {
                    return content
                }
            }
        }

        return nil
    }

    // MARK: - Rescan (periodic)

    private func rescanForNewSessions() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let detected = self?.scanRunningTerminals() ?? []

            DispatchQueue.main.async {
                guard let self = self else { return }

                let detectedPaths = Set(detected.map { $0.path })

                // 같은 프로젝트 세션 카운트
                var projectSessionCount: [String: Int] = [:]
                for session in detected {
                    projectSessionCount[session.path, default: 0] += 1
                }

                // 기존 탭 중 사라진 세션 → 완료 표시
                for tab in self.tabs {
                    if tab.detectedPid != nil && !detectedPaths.contains(tab.projectPath) {
                        tab.isCompleted = true
                        tab.claudeActivity = .done
                        tab.generateSummary()
                        AchievementManager.shared.checkCompletionAchievements(tab: tab)
                    }
                    // 세션 수 업데이트
                    tab.sessionCount = projectSessionCount[tab.projectPath] ?? tab.sessionCount
                }

                // 새 세션 추가
                for session in detected {
                    if !self.tabs.contains(where: { $0.projectPath == session.path }) {
                        self.addTab(
                            projectName: session.projectName,
                            projectPath: session.path,
                            isClaude: session.isClaude,
                            detectedPid: session.pid,
                            sessionCount: projectSessionCount[session.path] ?? 1,
                            branch: session.branch
                        )
                    }
                }
            }
        }
    }

    // MARK: - Helper: Process Info

    private func getCwd(pid: Int) -> String? {
        // lsof -d cwd
        if let out = shell("lsof -p \(pid) -d cwd -Fn 2>/dev/null | grep '^n/' | head -1") {
            let path = out.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "^n", with: "", options: .regularExpression)
            if !path.isEmpty && path != "/" { return path }
        }

        // Fallback: 열린 파일에서 프로젝트 경로 추론
        if let out = shell("lsof -p \(pid) -Fn 2>/dev/null | grep '/Users/' | grep -E '(develop|projects|src|code)' | grep -v Library | head -1") {
            var path = out.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "^n", with: "", options: .regularExpression)
            if !path.isEmpty && path != "/" {
                // git root 시도
                if let root = shell("git -C \"\(path)\" rev-parse --show-toplevel 2>/dev/null")?
                    .trimmingCharacters(in: .whitespacesAndNewlines), !root.isEmpty {
                    return root
                }
                // 파일이면 디렉토리로
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), !isDir.boolValue {
                    path = (path as NSString).deletingLastPathComponent
                }
                if path != NSHomeDirectory() { return path }
            }
        }

        return nil
    }

    private func getParentCwd(pid: Int) -> String? {
        // 부모 → 조부모 → 증조부모까지 3단계 탐색
        var current = pid
        for _ in 0..<3 {
            guard let ppidStr = shell("ps -p \(current) -o ppid= 2>/dev/null")?.trimmingCharacters(in: .whitespaces),
                  let ppid = Int(ppidStr), ppid > 1 else { return nil }
            if let cwd = getCwd(pid: ppid) { return cwd }
            current = ppid
        }
        return nil
    }

    private func getProjectName(path: String) -> String {
        // Use git repo root name if available
        if let toplevel = shell("git -C \"\(path)\" rev-parse --show-toplevel 2>/dev/null")?
            .trimmingCharacters(in: .whitespacesAndNewlines) {
            return (toplevel as NSString).lastPathComponent
        }
        return (path as NSString).lastPathComponent
    }

    private func getBranch(path: String) -> String? {
        return shell("git -C \"\(path)\" branch --show-current 2>/dev/null")?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func hasClaudeChild(pid: Int) -> Bool {
        if let children = shell("pgrep -P \(pid) 2>/dev/null") {
            for cpidStr in children.components(separatedBy: "\n") {
                if let cpid = Int(cpidStr.trimmingCharacters(in: .whitespaces)) {
                    if let cmdLine = shell("ps -p \(cpid) -o args= 2>/dev/null") {
                        let lower = cmdLine.lowercased()
                        if lower.contains("claude") || lower.contains("anthropic") {
                            return true
                        }
                    }
                    // Check grandchildren too
                    if hasClaudeChild(pid: cpid) { return true }
                }
            }
        }
        return false
    }

    private func getTerminalApp(pid: Int) -> String? {
        // Walk up the process tree to find the terminal app
        var currentPid = pid
        for _ in 0..<10 {
            guard let ppidStr = shell("ps -p \(currentPid) -o ppid= 2>/dev/null")?.trimmingCharacters(in: .whitespaces),
                  let ppid = Int(ppidStr), ppid > 1 else { break }

            if let cmd = shell("ps -p \(ppid) -o comm= 2>/dev/null")?.trimmingCharacters(in: .whitespaces) {
                if cmd.contains("Terminal") { return "Terminal" }
                if cmd.contains("iTerm") { return "iTerm2" }
                if cmd.contains("Warp") { return "Warp" }
                if cmd.contains("Alacritty") { return "Alacritty" }
                if cmd.contains("kitty") { return "kitty" }
                if cmd.contains("tmux") { return "tmux" }
            }
            currentPid = ppid
        }
        return nil
    }

    // MARK: - Tab Management

    func addTab(projectName: String, projectPath: String, isClaude: Bool = false, detectedPid: Int? = nil, sessionCount: Int = 1, branch: String? = nil, initialPrompt: String? = nil) {
        // CharacterRegistry에서 고용된 캐릭터 중 아직 배정 안 된 캐릭터 선택
        let registry = CharacterRegistry.shared
        let assignedNames = Set(tabs.map { $0.workerName })
        let available = registry.hiredCharacters.filter { !assignedNames.contains($0.name) }

        let name: String
        let color: Color
        let characterId: String?

        if let char = available.first {
            name = char.name
            color = Color(hex: char.shirtColor)
            characterId = char.id
        } else if !registry.hiredCharacters.isEmpty {
            // 모두 배정됐으면 라운드로빈 + 순번 붙이기
            let hired = registry.hiredCharacters
            let idx = tabs.count % hired.count
            let char = hired[idx]
            let sameCount = tabs.filter { $0.workerName.hasPrefix(char.name) }.count
            name = "\(char.name) \(sameCount + 1)"
            color = Color(hex: char.shirtColor)
            characterId = char.id
        } else {
            // 고용된 캐릭터가 없으면 기본값
            let baseName = workerNames[workerIndex % workerNames.count]
            let sameCount = tabs.filter { $0.workerName.hasPrefix(baseName) }.count
            name = sameCount > 0 ? "\(baseName) \(sameCount + 1)" : baseName
            color = Theme.workerColors[workerIndex % Theme.workerColors.count]
            characterId = nil
        }

        let tab = TerminalTab(
            id: UUID().uuidString,
            projectName: projectName,
            projectPath: projectPath,
            workerName: name,
            workerColor: color
        )
        tab.isClaude = isClaude
        tab.detectedPid = detectedPid
        tab.sessionCount = sessionCount
        tab.branch = branch
        tab.initialPrompt = initialPrompt
        tab.characterId = characterId

        tabs.append(tab)
        if activeTabId == nil {
            activeTabId = tab.id
        }
        workerIndex += 1

        tab.start()
    }

    func removeTab(_ id: String) {
        if let tab = tabs.first(where: { $0.id == id }) {
            tab.stop()
        }
        tabs.removeAll(where: { $0.id == id })
        if activeTabId == id {
            activeTabId = tabs.last?.id
        }
    }

    func selectTab(_ id: String) {
        activeTabId = id
    }

    func moveTab(from source: IndexSet, to destination: Int) {
        tabs.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Group Management

    func createGroup(name: String, color: Color, tabIds: [String]) {
        let group = SessionGroup(name: name, color: color, tabIds: tabIds)
        groups.append(group)
        for id in tabIds {
            tabs.first(where: { $0.id == id })?.groupId = group.id
        }
    }

    func addToGroup(tabId: String, groupId: String) {
        if let group = groups.first(where: { $0.id == groupId }) {
            if !group.tabIds.contains(tabId) {
                group.tabIds.append(tabId)
            }
            tabs.first(where: { $0.id == tabId })?.groupId = groupId
        }
    }

    func removeFromGroup(tabId: String) {
        if let tab = tabs.first(where: { $0.id == tabId }), let gid = tab.groupId {
            if let group = groups.first(where: { $0.id == gid }) {
                group.tabIds.removeAll(where: { $0 == tabId })
                if group.tabIds.isEmpty {
                    groups.removeAll(where: { $0.id == gid })
                }
            }
            tab.groupId = nil
        }
    }

    func deleteGroup(_ groupId: String) {
        for tab in tabs where tab.groupId == groupId {
            tab.groupId = nil
        }
        groups.removeAll(where: { $0.id == groupId })
    }

    func tabsInGroup(_ groupId: String) -> [TerminalTab] {
        tabs.filter { $0.groupId == groupId }
    }

    func ungroupedTabs() -> [TerminalTab] {
        tabs.filter { $0.groupId == nil }
    }

    // Feature 4: 세션 저장
    func saveSessions() {
        SessionStore.shared.save(tabs: tabs)
    }

    // Feature 4: 세션 복원 (이전 기록에서 경로 로드 - 같은 프로젝트 여러 탭 지원)
    func restoreSessions() {
        let saved = SessionStore.shared.load()
        for session in saved {
            // 완료된 세션은 복원하지 않음
            guard !session.isCompleted && FileManager.default.fileExists(atPath: session.projectPath) else { continue }
            addTab(
                projectName: session.projectName,
                projectPath: session.projectPath,
                branch: session.branch,
                initialPrompt: session.initialPrompt
            )
        }
    }

    /// Cmd+R: 전체 새로고침 - 기존 탭 정리 후 다시 스캔
    func refresh() {
        saveSessions() // 새로고침 전 저장
        // 기존 터미널 프로세스 정리
        for tab in tabs {
            tab.stop()
        }
        tabs.removeAll()
        activeTabId = nil
        workerIndex = 0

        // 다시 스캔
        autoDetectAndConnect()
    }

    func stopScanning() {
        scanTimer?.invalidate()
        scanTimer = nil
    }

    // MARK: - Shell Helper

    private func shell(_ command: String) -> String? {
        let process = Process()
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", command]
        // GUI 앱에서 PATH 보장
        var env = ProcessInfo.processInfo.environment
        let existing = env["PATH"] ?? "/usr/bin:/bin"
        let extra = ["/opt/homebrew/bin", "/usr/local/bin", "/opt/homebrew/sbin",
                     NSHomeDirectory() + "/.local/bin"]
        env["PATH"] = (extra + [existing]).joined(separator: ":")
        process.environment = env

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)
            return output?.isEmpty == true ? nil : output
        } catch {
            return nil
        }
    }
}

