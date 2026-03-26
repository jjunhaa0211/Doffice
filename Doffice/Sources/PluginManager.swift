import Foundation
import SwiftUI
import WebKit

// ═══════════════════════════════════════════════════════
// MARK: - Plugin Manifest (plugin.json)
// ═══════════════════════════════════════════════════════

/// 플러그인이 제공하는 확장 포인트 선언
struct PluginManifest: Codable {
    var name: String
    var version: String
    var description: String?
    var author: String?

    // 확장 포인트
    var contributes: PluginContributions?

    struct PluginContributions: Codable {
        var characters: String?        // "characters.json" 경로
        var panels: [PanelDecl]?       // 커스텀 패널 (WebView)
        var commands: [CommandDecl]?   // 명령어 (커맨드 팔레트 연동)
        var statusBar: [StatusBarDecl]? // 상태바 위젯
    }

    /// 커스텀 패널 — HTML/JS를 WKWebView로 렌더링
    struct PanelDecl: Codable, Identifiable {
        var id: String          // 고유 ID
        var title: String       // 탭 제목
        var icon: String?       // SF Symbol 이름
        var entry: String       // HTML 파일 경로 (plugin 디렉토리 기준)
        var position: String?   // "sidebar" | "panel" | "tab" (기본 "panel")
        var width: Int?         // 고정 너비 (옵션)
        var height: Int?        // 고정 높이 (옵션)
    }

    /// 명령어 — 스크립트 실행 + 커맨드 팔레트 등록
    struct CommandDecl: Codable, Identifiable {
        var id: String          // 고유 ID
        var title: String       // 표시 이름
        var icon: String?       // SF Symbol 이름
        var script: String      // 실행할 스크립트 경로 (plugin 디렉토리 기준)
        var keybinding: String? // 키바인딩 (옵션, 예: "cmd+shift+g")
    }

    /// 상태바 위젯
    struct StatusBarDecl: Codable, Identifiable {
        var id: String
        var script: String      // JSON 출력하는 스크립트 ({"text": "...", "icon": "...", "color": "..."})
        var interval: Int?      // 갱신 주기 (초, 기본 30)
    }
}

// ═══════════════════════════════════════════════════════
// MARK: - Plugin Host (런타임 플러그인 관리)
// ═══════════════════════════════════════════════════════

/// 활성 플러그인에서 로드된 확장 포인트들을 관리
class PluginHost: ObservableObject {
    static let shared = PluginHost()

    /// 활성 패널 목록
    @Published var panels: [LoadedPanel] = []
    /// 활성 명령어 목록
    @Published var commands: [LoadedCommand] = []
    /// 상태바 위젯 목록
    @Published var statusBarItems: [LoadedStatusBarItem] = []

    struct LoadedPanel: Identifiable {
        let id: String
        let pluginName: String
        let title: String
        let icon: String
        let htmlURL: URL
        let position: String
        let width: Int?
        let height: Int?
    }

    struct LoadedCommand: Identifiable {
        let id: String
        let pluginName: String
        let title: String
        let icon: String
        let scriptPath: String
    }

    struct LoadedStatusBarItem: Identifiable {
        let id: String
        let pluginName: String
        let scriptPath: String
        let interval: Int
        var text: String = ""
        var icon: String = ""
        var color: String = ""
    }

    func reload() {
        var newPanels: [LoadedPanel] = []
        var newCommands: [LoadedCommand] = []
        var newStatusBars: [LoadedStatusBarItem] = []

        for pluginPath in PluginManager.shared.activePluginPaths {
            let baseURL = URL(fileURLWithPath: pluginPath)
            let manifestURL = baseURL.appendingPathComponent("plugin.json")

            guard let data = try? Data(contentsOf: manifestURL),
                  let manifest = try? JSONDecoder().decode(PluginManifest.self, from: data),
                  let contributes = manifest.contributes else { continue }

            let pluginName = manifest.name

            // 패널
            if let panelDecls = contributes.panels {
                for decl in panelDecls {
                    let htmlURL = baseURL.appendingPathComponent(decl.entry)
                    guard FileManager.default.fileExists(atPath: htmlURL.path) else { continue }
                    newPanels.append(LoadedPanel(
                        id: "\(pluginName).\(decl.id)",
                        pluginName: pluginName,
                        title: decl.title,
                        icon: decl.icon ?? "puzzlepiece.fill",
                        htmlURL: htmlURL,
                        position: decl.position ?? "panel",
                        width: decl.width,
                        height: decl.height
                    ))
                }
            }

            // 명령어
            if let cmdDecls = contributes.commands {
                for decl in cmdDecls {
                    let scriptPath = baseURL.appendingPathComponent(decl.script).path
                    guard FileManager.default.fileExists(atPath: scriptPath) else { continue }
                    newCommands.append(LoadedCommand(
                        id: "\(pluginName).\(decl.id)",
                        pluginName: pluginName,
                        title: decl.title,
                        icon: decl.icon ?? "terminal",
                        scriptPath: scriptPath
                    ))
                }
            }

            // 상태바
            if let statusDecls = contributes.statusBar {
                for decl in statusDecls {
                    let scriptPath = baseURL.appendingPathComponent(decl.script).path
                    guard FileManager.default.fileExists(atPath: scriptPath) else { continue }
                    newStatusBars.append(LoadedStatusBarItem(
                        id: "\(pluginName).\(decl.id)",
                        pluginName: pluginName,
                        scriptPath: scriptPath,
                        interval: decl.interval ?? 30
                    ))
                }
            }
        }

        DispatchQueue.main.async {
            self.panels = newPanels
            self.commands = newCommands
            self.statusBarItems = newStatusBars
            self.startStatusBarTimers()
        }
    }

    // MARK: - 명령어 실행

    func executeCommand(_ command: LoadedCommand, projectPath: String? = nil) {
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", command.scriptPath]
            if let path = projectPath {
                process.currentDirectoryURL = URL(fileURLWithPath: path)
            }
            process.environment = ProcessInfo.processInfo.environment
            try? process.run()
            process.waitUntilExit()
        }
    }

    // MARK: - 상태바 타이머

    private var statusTimers: [String: Timer] = [:]

    private func startStatusBarTimers() {
        // 기존 타이머 정리
        for timer in statusTimers.values { timer.invalidate() }
        statusTimers.removeAll()

        for item in statusBarItems {
            refreshStatusBarItem(item.id)
            let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(item.interval), repeats: true) { [weak self] _ in
                self?.refreshStatusBarItem(item.id)
            }
            statusTimers[item.id] = timer
        }
    }

    private func refreshStatusBarItem(_ id: String) {
        guard let idx = statusBarItems.firstIndex(where: { $0.id == id }) else { return }
        let item = statusBarItems[idx]

        DispatchQueue.global(qos: .utility).async { [weak self] in
            let process = Process()
            let pipe = Pipe()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", item.scriptPath]
            process.standardOutput = pipe
            process.environment = ProcessInfo.processInfo.environment
            try? process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

            DispatchQueue.main.async {
                guard let self = self,
                      let idx = self.statusBarItems.firstIndex(where: { $0.id == id }) else { return }
                self.statusBarItems[idx].text = json["text"] as? String ?? ""
                self.statusBarItems[idx].icon = json["icon"] as? String ?? ""
                self.statusBarItems[idx].color = json["color"] as? String ?? ""
            }
        }
    }
}

// ═══════════════════════════════════════════════════════
// MARK: - Plugin Panel View (WKWebView 래퍼)
// ═══════════════════════════════════════════════════════

struct PluginPanelView: NSViewRepresentable {
    let htmlURL: URL
    let pluginName: String

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        // 플러그인 JS에서 앱과 통신할 수 있는 메시지 핸들러
        let handler = PluginMessageHandler()
        config.userContentController.add(handler, name: "doffice")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: htmlURL)
        webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
        webView.load(request)
    }
}

/// 플러그인 JS → 앱 통신 핸들러
class PluginMessageHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let action = body["action"] as? String else { return }

        switch action {
        case "getSessionInfo":
            // 세션 정보를 JS에 전달
            NotificationCenter.default.post(name: .pluginRequestSessionInfo, object: message.webView)
        case "notify":
            if let text = body["text"] as? String {
                NotificationCenter.default.post(name: .pluginNotify, object: nil, userInfo: ["text": text])
            }
        default:
            break
        }
    }
}

extension Notification.Name {
    static let pluginRequestSessionInfo = Notification.Name("pluginRequestSessionInfo")
    static let pluginNotify = Notification.Name("pluginNotify")
    static let pluginReload = Notification.Name("pluginReload")
}

// ═══════════════════════════════════════════════════════
// MARK: - Plugin Manager (Homebrew 플러그인 관리)
// ═══════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════
// MARK: - Registry Item (마켓플레이스 항목)
// ═══════════════════════════════════════════════════════

/// 원격 레지스트리에 등록된 플러그인 (GitHub registry.json)
struct RegistryPlugin: Codable, Identifiable, Equatable {
    let id: String              // 고유 식별자
    var name: String            // 표시 이름
    var author: String          // 제작자
    var description: String     // 설명
    var version: String         // 최신 버전
    var downloadURL: String     // tar.gz / zip 다운로드 URL
    var characterCount: Int     // 포함된 캐릭터 수
    var tags: [String]          // 태그 (예: ["cat", "pixel-art", "korean"])
    var previewImageURL: String? // 미리보기 이미지 URL (옵션)
    var stars: Int?             // 인기도 (옵션)
}

/// 플러그인 메타데이터
struct PluginEntry: Codable, Identifiable, Equatable {
    let id: String          // UUID
    var name: String        // 표시 이름
    var source: String      // brew formula 또는 tap URL (예: "user/tap/formula")
    var localPath: String   // 설치된 로컬 경로
    var version: String     // 버전
    var installedAt: Date
    var enabled: Bool
    var sourceType: SourceType

    enum SourceType: String, Codable {
        case brewFormula    // brew install <formula>
        case brewTap        // brew tap <user/repo> → brew install <formula>
        case rawURL         // curl로 직접 다운로드
        case local          // 로컬 디렉토리 직접 링크
    }
}

class PluginManager: ObservableObject {
    static let shared = PluginManager()

    @Published var plugins: [PluginEntry] = []
    @Published var isInstalling: Bool = false
    @Published var installProgress: String = ""
    @Published var lastError: String?

    // 마켓플레이스
    @Published var registryPlugins: [RegistryPlugin] = []
    @Published var isLoadingRegistry: Bool = false
    @Published var registryError: String?

    private let storageKey = "WorkManPlugins"
    private let pluginBaseDir: URL

    /// 레지스트리 URL — GitHub Pages 또는 raw 파일
    /// 기여자는 이 저장소에 PR로 registry.json에 자기 플러그인을 추가
    static let registryURL = "https://raw.githubusercontent.com/jjunhaa0211/doffice-plugins/main/registry.json"

    private init() {
        // ~/Library/Application Support/WorkMan/Plugins
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            pluginBaseDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("WorkManPlugins")
            try? FileManager.default.createDirectory(at: pluginBaseDir, withIntermediateDirectories: true)
            loadPlugins()
            return
        }
        pluginBaseDir = appSupport.appendingPathComponent("WorkMan").appendingPathComponent("Plugins")
        try? FileManager.default.createDirectory(at: pluginBaseDir, withIntermediateDirectories: true)
        loadPlugins()
    }

    // MARK: - Persistence

    private func loadPlugins() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([PluginEntry].self, from: data) else { return }
        plugins = decoded
    }

    private func savePlugins() {
        if let data = try? JSONEncoder().encode(plugins) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    // MARK: - 활성 플러그인 경로 목록 (세션에 주입)

    var activePluginPaths: [String] {
        plugins.filter { $0.enabled && FileManager.default.fileExists(atPath: $0.localPath) }
            .map { $0.localPath }
    }

    // MARK: - 마켓플레이스 (레지스트리)

    func fetchRegistry() {
        isLoadingRegistry = true
        registryError = nil

        guard let url = URL(string: Self.registryURL) else {
            registryError = "Invalid registry URL"
            isLoadingRegistry = false
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoadingRegistry = false

                if let error = error {
                    self.registryError = error.localizedDescription
                    return
                }
                guard let data = data else {
                    self.registryError = "No data received"
                    return
                }
                do {
                    let items = try JSONDecoder().decode([RegistryPlugin].self, from: data)
                    self.registryPlugins = items
                } catch {
                    self.registryError = "JSON parse error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    /// 레지스트리에서 설치
    func installFromRegistry(_ item: RegistryPlugin) {
        install(source: item.downloadURL)
    }

    /// 이미 설치되어 있는지 확인
    func isInstalled(_ registryItem: RegistryPlugin) -> Bool {
        plugins.contains { $0.source == registryItem.downloadURL || $0.name == registryItem.name }
    }

    // MARK: - 소스 타입 자동 감지

    func detectSourceType(_ input: String) -> PluginEntry.SourceType {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        // 로컬 경로 (/, ~/ 로 시작)
        let expanded = NSString(string: trimmed).expandingTildeInPath
        if trimmed.hasPrefix("/") || trimmed.hasPrefix("~/") || trimmed.hasPrefix("./") {
            if FileManager.default.fileExists(atPath: expanded) {
                return .local
            }
        }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return .rawURL
        }
        // "user/tap/formula" 형식 → brew tap
        let components = trimmed.split(separator: "/")
        if components.count >= 3 && !trimmed.hasPrefix("/") {
            return .brewTap
        }
        // 단순 formula 이름
        return .brewFormula
    }

    // MARK: - 설치

    func install(source: String) {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isInstalling = true
        lastError = nil
        installProgress = NSLocalizedString("plugin.progress.analyzing", comment: "")

        let sourceType = detectSourceType(trimmed)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            switch sourceType {
            case .brewFormula:
                self.installBrewFormula(trimmed)
            case .brewTap:
                self.installBrewTap(trimmed)
            case .rawURL:
                self.installFromURL(trimmed)
            case .local:
                self.installLocal(trimmed)
            }
        }
    }

    private func installBrewFormula(_ formula: String) {
        updateProgress(NSLocalizedString("plugin.progress.brew.install", comment: ""))

        let brewPath = Self.findBrewPath()
        guard let brew = brewPath else {
            finishWithError(NSLocalizedString("plugin.error.brew.not.found", comment: ""))
            return
        }

        // brew install
        let (installOk, installOut) = runShell("\(brew) install \(shellEscape(formula))")
        if !installOk && !installOut.contains("already installed") {
            finishWithError(String(format: NSLocalizedString("plugin.error.install.failed", comment: ""), installOut))
            return
        }

        // brew --prefix로 설치 경로 가져오기
        let (_, prefixOut) = runShell("\(brew) --prefix \(shellEscape(formula))")
        let prefix = prefixOut.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !prefix.isEmpty && FileManager.default.fileExists(atPath: prefix) else {
            finishWithError(NSLocalizedString("plugin.error.path.not.found", comment: ""))
            return
        }

        // 버전 확인
        let (_, versionOut) = runShell("\(brew) list --versions \(shellEscape(formula))")
        let version = versionOut.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: " ").last ?? "unknown"

        let entry = PluginEntry(
            id: UUID().uuidString,
            name: formula,
            source: formula,
            localPath: prefix,
            version: version,
            installedAt: Date(),
            enabled: true,
            sourceType: .brewFormula
        )

        finishInstall(entry)
    }

    private func installBrewTap(_ tapFormula: String) {
        let parts = tapFormula.split(separator: "/")
        guard parts.count >= 3 else {
            finishWithError(NSLocalizedString("plugin.error.invalid.tap", comment: ""))
            return
        }

        let tapName = "\(parts[0])/\(parts[1])"
        let formula = String(parts[2...].joined(separator: "/"))

        let brewPath = Self.findBrewPath()
        guard let brew = brewPath else {
            finishWithError(NSLocalizedString("plugin.error.brew.not.found", comment: ""))
            return
        }

        // brew tap
        updateProgress(String(format: NSLocalizedString("plugin.progress.tapping", comment: ""), tapName))
        let (tapOk, tapOut) = runShell("\(brew) tap \(shellEscape(String(tapName)))")
        if !tapOk && !tapOut.contains("already tapped") {
            finishWithError(String(format: NSLocalizedString("plugin.error.tap.failed", comment: ""), tapOut))
            return
        }

        // brew install
        updateProgress(String(format: NSLocalizedString("plugin.progress.installing", comment: ""), formula))
        let (installOk, installOut) = runShell("\(brew) install \(shellEscape(tapFormula))")
        if !installOk && !installOut.contains("already installed") {
            finishWithError(String(format: NSLocalizedString("plugin.error.install.failed", comment: ""), installOut))
            return
        }

        // 경로 가져오기
        let (_, prefixOut) = runShell("\(brew) --prefix \(shellEscape(tapFormula))")
        let prefix = prefixOut.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !prefix.isEmpty && FileManager.default.fileExists(atPath: prefix) else {
            finishWithError(NSLocalizedString("plugin.error.path.not.found", comment: ""))
            return
        }

        let (_, versionOut) = runShell("\(brew) list --versions \(shellEscape(tapFormula))")
        let version = versionOut.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: " ").last ?? "unknown"

        let entry = PluginEntry(
            id: UUID().uuidString,
            name: formula,
            source: tapFormula,
            localPath: prefix,
            version: version,
            installedAt: Date(),
            enabled: true,
            sourceType: .brewTap
        )

        finishInstall(entry)
    }

    private func installFromURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            finishWithError(NSLocalizedString("plugin.error.invalid.url", comment: ""))
            return
        }

        let fileName = url.lastPathComponent.isEmpty ? "plugin" : url.lastPathComponent
        let pluginName = (fileName as NSString).deletingPathExtension
        let pluginDir = pluginBaseDir.appendingPathComponent(pluginName)

        updateProgress(String(format: NSLocalizedString("plugin.progress.downloading", comment: ""), fileName))

        // 디렉토리 생성
        try? FileManager.default.createDirectory(at: pluginDir, withIntermediateDirectories: true)

        // curl로 다운로드
        let destPath = pluginDir.appendingPathComponent(fileName).path
        let (ok, output) = runShell("curl -fsSL -o \(shellEscape(destPath)) \(shellEscape(urlString))")
        if !ok {
            finishWithError(String(format: NSLocalizedString("plugin.error.download.failed", comment: ""), output))
            return
        }

        // tar/zip이면 압축 해제
        if fileName.hasSuffix(".tar.gz") || fileName.hasSuffix(".tgz") {
            updateProgress(NSLocalizedString("plugin.progress.extracting", comment: ""))
            let (extractOk, extractOut) = runShell("tar -xzf \(shellEscape(destPath)) -C \(shellEscape(pluginDir.path))")
            if !extractOk {
                finishWithError(String(format: NSLocalizedString("plugin.error.extract.failed", comment: ""), extractOut))
                return
            }
            try? FileManager.default.removeItem(atPath: destPath)
        } else if fileName.hasSuffix(".zip") {
            updateProgress(NSLocalizedString("plugin.progress.extracting", comment: ""))
            let (extractOk, extractOut) = runShell("unzip -o \(shellEscape(destPath)) -d \(shellEscape(pluginDir.path))")
            if !extractOk {
                finishWithError(String(format: NSLocalizedString("plugin.error.extract.failed", comment: ""), extractOut))
                return
            }
            try? FileManager.default.removeItem(atPath: destPath)
        }

        let entry = PluginEntry(
            id: UUID().uuidString,
            name: pluginName,
            source: urlString,
            localPath: pluginDir.path,
            version: "1.0.0",
            installedAt: Date(),
            enabled: true,
            sourceType: .rawURL
        )

        finishInstall(entry)
    }

    // MARK: - 로컬 디렉토리 등록

    private func installLocal(_ path: String) {
        let expanded = NSString(string: path).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: expanded) else {
            finishWithError(NSLocalizedString("plugin.error.path.not.found", comment: ""))
            return
        }

        let name = URL(fileURLWithPath: expanded).lastPathComponent
        let validation = Self.validatePluginDir(expanded)

        let entry = PluginEntry(
            id: UUID().uuidString,
            name: name,
            source: path,
            localPath: expanded,
            version: validation.version ?? "dev",
            installedAt: Date(),
            enabled: true,
            sourceType: .local
        )

        finishInstall(entry)
    }

    // MARK: - 플러그인 유효성 검증

    struct PluginValidation {
        var isValid: Bool
        var hasClaudeMD: Bool
        var hasHooks: Bool
        var hasSlashCommands: Bool
        var hasMCPServers: Bool
        var hasSettings: Bool
        var hasCharacters: Bool
        var characterCount: Int
        var version: String?
        var warnings: [String]
    }

    static func validatePluginDir(_ path: String) -> PluginValidation {
        let fm = FileManager.default
        let base = URL(fileURLWithPath: path)

        let claudeMD = base.appendingPathComponent("CLAUDE.md")
        let hooksDir = base.appendingPathComponent("hooks")
        let slashDir = base.appendingPathComponent("slash-commands")
        let mcpDir = base.appendingPathComponent("mcp-servers")
        let settingsFile = base.appendingPathComponent("settings.json")
        let packageJSON = base.appendingPathComponent("package.json")

        let charactersFile = base.appendingPathComponent("characters.json")

        let hasClaudeMD = fm.fileExists(atPath: claudeMD.path)
        let hasHooks = fm.fileExists(atPath: hooksDir.path)
        let hasSlashCommands = fm.fileExists(atPath: slashDir.path)
        let hasMCPServers = fm.fileExists(atPath: mcpDir.path)
        let hasSettings = fm.fileExists(atPath: settingsFile.path)
        let hasCharacters = fm.fileExists(atPath: charactersFile.path)

        var characterCount = 0
        if hasCharacters,
           let data = try? Data(contentsOf: charactersFile),
           let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            characterCount = arr.count
        }

        var version: String?
        if let data = try? Data(contentsOf: packageJSON),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let v = json["version"] as? String {
            version = v
        }

        var warnings: [String] = []
        let hasAnything = hasClaudeMD || hasHooks || hasSlashCommands || hasMCPServers || hasSettings || hasCharacters
        if !hasAnything {
            warnings.append(NSLocalizedString("plugin.warn.empty", comment: ""))
        }

        return PluginValidation(
            isValid: hasAnything,
            hasClaudeMD: hasClaudeMD,
            hasHooks: hasHooks,
            hasSlashCommands: hasSlashCommands,
            hasMCPServers: hasMCPServers,
            hasSettings: hasSettings,
            hasCharacters: hasCharacters,
            characterCount: characterCount,
            version: version,
            warnings: warnings
        )
    }

    // MARK: - 새 플러그인 스캐폴딩

    func scaffold(name: String, at parentDir: String, options: ScaffoldOptions = ScaffoldOptions()) -> String? {
        let pluginDir = URL(fileURLWithPath: parentDir).appendingPathComponent(name)
        let fm = FileManager.default

        do {
            try fm.createDirectory(at: pluginDir, withIntermediateDirectories: true)

            // CLAUDE.md
            let claudeMD = """
            # \(name) Plugin

            이 플러그인은 도피스(Doffice)용 Claude Code 플러그인입니다.

            ## 설명
            플러그인 설명을 여기에 작성하세요.
            """
            try claudeMD.write(to: pluginDir.appendingPathComponent("CLAUDE.md"), atomically: true, encoding: .utf8)

            // hooks/
            if options.includeHooks {
                let hooksDir = pluginDir.appendingPathComponent("hooks")
                try fm.createDirectory(at: hooksDir, withIntermediateDirectories: true)

                let preHook = """
                // preToolUse hook — 도구 실행 전에 호출됩니다.
                // return { decision: "allow" } 또는 { decision: "deny", reason: "..." }
                export default function preToolUse({ tool, input }) {
                  // 예: 특정 디렉토리 보호
                  // if (tool === "Write" && input.file_path?.startsWith("/protected/")) {
                  //   return { decision: "deny", reason: "보호된 디렉토리입니다" };
                  // }
                  return { decision: "allow" };
                }
                """
                try preHook.write(to: hooksDir.appendingPathComponent("preToolUse.js"), atomically: true, encoding: .utf8)
            }

            // slash-commands/
            if options.includeSlashCommands {
                let slashDir = pluginDir.appendingPathComponent("slash-commands")
                try fm.createDirectory(at: slashDir, withIntermediateDirectories: true)

                let exampleCmd = """
                # /\(name)-hello

                사용자에게 인사를 건네세요.
                이 명령은 \(name) 플러그인의 예제입니다.
                """
                try exampleCmd.write(to: slashDir.appendingPathComponent("\(name)-hello.md"), atomically: true, encoding: .utf8)
            }

            // settings.json
            if options.includeSettings {
                let settings: [String: Any] = [
                    "name": name,
                    "version": "0.1.0",
                    "description": "\(name) plugin for Doffice"
                ]
                let data = try JSONSerialization.data(withJSONObject: settings, options: .prettyPrinted)
                try data.write(to: pluginDir.appendingPathComponent("settings.json"))
            }

            // characters.json (캐릭터 팩)
            if options.includeCharacters {
                let exampleCharacters: [[String: Any]] = [
                    [
                        "id": "example_char",
                        "name": "Example",
                        "archetype": "예제 캐릭터",
                        "hairColor": "4a3728",
                        "skinTone": "ffd5b8",
                        "shirtColor": "f08080",
                        "pantsColor": "3a4050",
                        "hatType": "none",
                        "accessory": "glasses",
                        "species": "Human",
                        "jobRole": "developer"
                    ]
                ]
                let charData = try JSONSerialization.data(withJSONObject: exampleCharacters, options: .prettyPrinted)
                try charData.write(to: pluginDir.appendingPathComponent("characters.json"))

                // README
                let readme = """
                # \(name) 캐릭터 팩

                ## characters.json 형식

                ```json
                [
                  {
                    "id": "고유ID",
                    "name": "표시 이름",
                    "archetype": "성격/설명",
                    "hairColor": "hex (6자리, # 없이)",
                    "skinTone": "hex",
                    "shirtColor": "hex",
                    "pantsColor": "hex",
                    "hatType": "none|beanie|cap|hardhat|wizard|crown|headphones|beret",
                    "accessory": "none|glasses|sunglasses|scarf|mask|earring",
                    "species": "Human|Cat|Dog|Rabbit|Bear|Penguin|Fox|Robot|Claude|Alien|Ghost|Dragon|Chicken|Owl|Frog|Panda|Unicorn|Skeleton",
                    "jobRole": "developer|qa|reporter|boss|planner|reviewer|designer|sre"
                  }
                ]
                ```

                ## 배포 방법
                1. GitHub에 올리고 Homebrew tap 생성
                2. 또는 tar.gz로 묶어서 Release에 올리기
                3. 도피스 설정 > 플러그인에서 설치
                """
                try readme.write(to: pluginDir.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
            }

            // plugin.json (매니페스트 — 확장 포인트 선언)
            var contributes: [String: Any] = [:]
            if options.includeCharacters {
                contributes["characters"] = "characters.json"
            }
            if options.includePanel {
                contributes["panels"] = [[
                    "id": "main-panel",
                    "title": "\(name) Panel",
                    "icon": "puzzlepiece.fill",
                    "entry": "panel/index.html",
                    "position": "panel"
                ]]

                // panel/index.html 생성
                let panelDir = pluginDir.appendingPathComponent("panel")
                try fm.createDirectory(at: panelDir, withIntermediateDirectories: true)
                let panelHTML = """
                <!DOCTYPE html>
                <html>
                <head>
                <meta charset="utf-8">
                <style>
                  * { margin: 0; padding: 0; box-sizing: border-box; }
                  body {
                    font-family: 'SF Mono', 'Menlo', monospace;
                    background: transparent;
                    color: #e0e0e0;
                    padding: 16px;
                  }
                  h1 { font-size: 14px; margin-bottom: 12px; color: #5b9cf6; }
                  .card {
                    background: rgba(255,255,255,0.05);
                    border: 1px solid rgba(255,255,255,0.1);
                    border-radius: 8px;
                    padding: 12px;
                    margin-bottom: 8px;
                  }
                  button {
                    background: #5b9cf6;
                    color: white;
                    border: none;
                    border-radius: 6px;
                    padding: 8px 16px;
                    font-family: inherit;
                    font-size: 12px;
                    cursor: pointer;
                  }
                  button:hover { opacity: 0.8; }
                </style>
                </head>
                <body>
                  <h1>\(name) Plugin</h1>
                  <div class="card">
                    <p>이 패널은 플러그인의 예제입니다.</p>
                    <p>HTML/CSS/JS로 자유롭게 UI를 만들 수 있습니다.</p>
                  </div>
                  <button onclick="window.webkit.messageHandlers.doffice.postMessage({action:'notify', text:'Hello from \(name)!'})">
                    앱에 알림 보내기
                  </button>
                  <script>
                    // window.webkit.messageHandlers.doffice.postMessage({action: 'getSessionInfo'})
                    // → 앱이 세션 정보를 이 WebView에 전달
                  </script>
                </body>
                </html>
                """
                try panelHTML.write(to: panelDir.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)
            }

            let pluginJSON: [String: Any] = [
                "name": name,
                "version": "0.1.0",
                "description": "\(name) — Doffice plugin",
                "author": NSUserName(),
                "contributes": contributes
            ]
            let pluginData = try JSONSerialization.data(withJSONObject: pluginJSON, options: [.prettyPrinted, .sortedKeys])
            try pluginData.write(to: pluginDir.appendingPathComponent("plugin.json"))

            // package.json (버전 추적용)
            let packageJSON: [String: Any] = [
                "name": name,
                "version": "0.1.0",
                "description": "\(name) — Doffice plugin"
            ]
            let pkgData = try JSONSerialization.data(withJSONObject: packageJSON, options: .prettyPrinted)
            try pkgData.write(to: pluginDir.appendingPathComponent("package.json"))

            return pluginDir.path
        } catch {
            return nil
        }
    }

    struct ScaffoldOptions {
        var includeHooks: Bool = true
        var includeSlashCommands: Bool = true
        var includeCharacters: Bool = true
        var includeSettings: Bool = true
        var includePanel: Bool = true
    }

    // MARK: - Finder에서 열기

    func revealInFinder(_ plugin: PluginEntry) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: plugin.localPath)
    }

    // MARK: - 삭제

    func uninstall(_ plugin: PluginEntry) {
        switch plugin.sourceType {
        case .brewFormula, .brewTap:
            if let brew = Self.findBrewPath() {
                _ = runShell("\(brew) uninstall \(shellEscape(plugin.source))")
            }
        case .rawURL:
            try? FileManager.default.removeItem(atPath: plugin.localPath)
        case .local:
            break // 로컬 디렉토리는 삭제하지 않고 등록만 해제
        }

        DispatchQueue.main.async {
            self.plugins.removeAll { $0.id == plugin.id }
            self.savePlugins()
            // 제거된 플러그인 정리
            CharacterRegistry.shared.removeInactivePluginCharacters()
            PluginHost.shared.reload()
        }
    }

    // MARK: - 토글

    func toggleEnabled(_ plugin: PluginEntry) {
        if let idx = plugins.firstIndex(where: { $0.id == plugin.id }) {
            plugins[idx].enabled.toggle()
            savePlugins()
        }
    }

    // MARK: - 업데이트 (brew upgrade)

    func upgrade(_ plugin: PluginEntry) {
        guard plugin.sourceType != .rawURL else { return }
        guard let brew = Self.findBrewPath() else { return }

        isInstalling = true
        installProgress = String(format: NSLocalizedString("plugin.progress.upgrading", comment: ""), plugin.name)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let (ok, output) = self.runShell("\(brew) upgrade \(self.shellEscape(plugin.source))")

            if !ok && !output.contains("already installed") && !output.contains("already the newest") {
                self.finishWithError(String(format: NSLocalizedString("plugin.error.upgrade.failed", comment: ""), output))
                return
            }

            // 새 버전 확인
            let (_, versionOut) = self.runShell("\(brew) list --versions \(self.shellEscape(plugin.source))")
            let version = versionOut.trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: " ").last ?? plugin.version

            DispatchQueue.main.async {
                if let idx = self.plugins.firstIndex(where: { $0.id == plugin.id }) {
                    self.plugins[idx].version = version
                    self.savePlugins()
                }
                self.isInstalling = false
                self.installProgress = ""
            }
        }
    }

    // MARK: - Shell Helpers

    private static func findBrewPath() -> String? {
        let candidates = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
        return candidates.first { FileManager.default.fileExists(atPath: $0) }
    }

    @discardableResult
    private func runShell(_ command: String) -> (Bool, String) {
        let process = Process()
        let pipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        process.standardOutput = pipe
        process.standardError = errorPipe
        process.environment = ProcessInfo.processInfo.environment

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return (false, error.localizedDescription)
        }

        let outData = pipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outData, encoding: .utf8) ?? ""
        let errOutput = String(data: errData, encoding: .utf8) ?? ""

        let success = process.terminationStatus == 0
        return (success, success ? output : (errOutput.isEmpty ? output : errOutput))
    }

    private func shellEscape(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    // MARK: - Progress Helpers

    private func updateProgress(_ msg: String) {
        DispatchQueue.main.async { self.installProgress = msg }
    }

    private func finishWithError(_ msg: String) {
        DispatchQueue.main.async {
            self.lastError = msg
            self.isInstalling = false
            self.installProgress = ""
        }
    }

    private func finishInstall(_ entry: PluginEntry) {
        DispatchQueue.main.async {
            // 중복 체크
            if self.plugins.contains(where: { $0.source == entry.source }) {
                self.lastError = NSLocalizedString("plugin.error.already.installed", comment: "")
            } else {
                self.plugins.append(entry)
                self.savePlugins()
                // 캐릭터 팩 + 확장 포인트 로드
                CharacterRegistry.shared.loadPluginCharacters()
                PluginHost.shared.reload()
            }
            self.isInstalling = false
            self.installProgress = ""
        }
    }
}
