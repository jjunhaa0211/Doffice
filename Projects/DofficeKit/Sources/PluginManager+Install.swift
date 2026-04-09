import Foundation
import DesignSystem

extension PluginManager {

    // MARK: - 설치

    public func install(source: String) {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isInstalling = true
        lastError = nil
        installProgress = NSLocalizedString("plugin.progress.analyzing", comment: "")

        let sourceType = detectSourceType(trimmed)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            switch sourceType {
            #if os(macOS)
            case .brewFormula:
                self.installBrewFormula(trimmed)
            case .brewTap:
                self.installBrewTap(trimmed)
            #else
            case .brewFormula, .brewTap:
                self.finishWithError(NSLocalizedString("plugin.error.brew.not.supported", comment: ""))
            #endif
            case .rawURL:
                self.installFromURL(trimmed)
            case .local:
                self.installLocal(trimmed)
            }
        }
    }

    func installBundledPlugin(_ item: RegistryPlugin, bundledID: String) {
        guard let bundled = Self.bundledPluginDefinition(for: bundledID) else {
            finishWithError(NSLocalizedString("plugin.error.path.not.found", comment: ""))
            return
        }

        isInstalling = true
        lastError = nil
        installProgress = String(format: NSLocalizedString("plugin.progress.installing", comment: ""), item.name)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let fm = FileManager.default
            let pluginDir = self.pluginBaseDir.appendingPathComponent(bundled.directoryName)

            do {
                if fm.fileExists(atPath: pluginDir.path) {
                    try fm.removeItem(at: pluginDir)
                }
                try fm.createDirectory(at: pluginDir, withIntermediateDirectories: true)

                for file in bundled.files {
                    let destination = pluginDir.appendingPathComponent(file.path)
                    let parentDir = destination.deletingLastPathComponent()
                    try fm.createDirectory(at: parentDir, withIntermediateDirectories: true)
                    try file.contents.write(to: destination, atomically: true, encoding: .utf8)
                }
            } catch {
                self.finishWithError(error.localizedDescription)
                return
            }

            if let validationMessage = self.pluginValidationError(at: pluginDir.path) {
                self.cleanupManagedPluginDirectory(pluginDir)
                self.finishWithError(validationMessage)
                return
            }

            let entry = PluginEntry(
                id: UUID().uuidString,
                name: item.name,
                source: item.downloadURL,
                localPath: pluginDir.path,
                version: item.version,
                installedAt: Date(),
                enabled: true,
                sourceType: .rawURL
            )
            self.finishInstall(entry)
        }
    }

    #if os(macOS)
    func installBrewFormula(_ formula: String) {
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

        if let validationMessage = pluginValidationError(at: prefix) {
            finishWithError(validationMessage)
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

    func installBrewTap(_ tapFormula: String) {
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

        if let validationMessage = pluginValidationError(at: prefix) {
            finishWithError(validationMessage)
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
    #endif

    func installFromURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            finishWithError(NSLocalizedString("plugin.error.invalid.url", comment: ""))
            return
        }

        let fileName = url.lastPathComponent.isEmpty ? "plugin" : url.lastPathComponent
        let pluginName = (fileName as NSString).deletingPathExtension
        let pluginDir = pluginBaseDir.appendingPathComponent(pluginName)
        let fm = FileManager.default

        updateProgress(String(format: NSLocalizedString("plugin.progress.downloading", comment: ""), fileName))
        do {
            if fm.fileExists(atPath: pluginDir.path) {
                try fm.removeItem(at: pluginDir)
            }
            try fm.createDirectory(at: pluginDir, withIntermediateDirectories: true)
        } catch {
            finishWithError(String(format: NSLocalizedString("plugin.error.download.failed", comment: ""), error.localizedDescription))
            return
        }

        let destURL = pluginDir.appendingPathComponent(fileName)
        downloadHandler(url, destURL) { [weak self] result in
            guard let self = self else { return }
            if case let .failure(error) = result {
                self.finishWithError(String(format: NSLocalizedString("plugin.error.download.failed", comment: ""), error.localizedDescription))
                return
            }

            // 압축 해제
            if let message = self.extractIfNeeded(destURL, to: pluginDir, fileName: fileName) {
                self.cleanupManagedPluginDirectory(pluginDir)
                self.finishWithError(message)
                return
            }

            if let validationMessage = self.pluginValidationError(at: pluginDir.path) {
                self.cleanupManagedPluginDirectory(pluginDir)
                self.finishWithError(validationMessage)
                return
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
            self.finishInstall(entry)
        }
    }

    func extractIfNeeded(_ fileURL: URL, to dir: URL, fileName: String) -> String? {
        #if os(macOS)
        if fileName.hasSuffix(".tar.gz") || fileName.hasSuffix(".tgz") {
            updateProgress(NSLocalizedString("plugin.progress.extracting", comment: ""))
            let (ok, out) = runShell("tar -xzf \(shellEscape(fileURL.path)) -C \(shellEscape(dir.path))")
            if ok {
                try? FileManager.default.removeItem(at: fileURL)
                return nil
            }
            return String(format: NSLocalizedString("plugin.error.extract.failed", comment: ""), out)
        } else if fileName.hasSuffix(".zip") {
            updateProgress(NSLocalizedString("plugin.progress.extracting", comment: ""))
            let (ok, out) = runShell("unzip -o \(shellEscape(fileURL.path)) -d \(shellEscape(dir.path))")
            if ok {
                try? FileManager.default.removeItem(at: fileURL)
                return nil
            }
            return String(format: NSLocalizedString("plugin.error.extract.failed", comment: ""), out)
        }
        #else
        // iOS: zip만 Foundation으로 지원 (tar.gz는 미지원)
        if fileName.hasSuffix(".zip") {
            updateProgress(NSLocalizedString("plugin.progress.extracting", comment: ""))
            // FileManager에서 직접 압축해제는 미지원 → 파일 그대로 유지
        }
        #endif
        return nil
    }

    // MARK: - 로컬 디렉토리 등록

    func installLocal(_ path: String) {
        let expanded = NSString(string: path).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: expanded) else {
            finishWithError(NSLocalizedString("plugin.error.path.not.found", comment: ""))
            return
        }

        let name = URL(fileURLWithPath: expanded).lastPathComponent
        let validation = Self.validatePluginDir(expanded)
        guard validation.isValid else {
            finishWithError(validation.warnings.first ?? NSLocalizedString("plugin.warn.empty", comment: ""))
            return
        }

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

    public struct PluginValidation {
        public var isValid: Bool
        public var hasClaudeMD: Bool
        public var hasHooks: Bool
        public var hasSlashCommands: Bool
        public var hasMCPServers: Bool
        public var hasSettings: Bool
        public var hasCharacters: Bool
        public var characterCount: Int
        public var version: String?
        public var warnings: [String]
    }

    public static func validatePluginDir(_ path: String) -> PluginValidation {
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

        // plugin.json의 contributes 필드 체크 (effects, furniture, themes 등)
        let pluginJSON = base.appendingPathComponent("plugin.json")
        var hasPluginContributes = false
        if fm.fileExists(atPath: pluginJSON.path),
           let data = try? Data(contentsOf: pluginJSON),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let contributes = json["contributes"] as? [String: Any],
           !contributes.isEmpty {
            hasPluginContributes = true
            // plugin.json에서 버전 추출 (package.json 없을 때)
            if version == nil, let v = json["version"] as? String { version = v }
        }

        var warnings: [String] = []
        let hasAnything = hasClaudeMD || hasHooks || hasSlashCommands || hasMCPServers || hasSettings || hasCharacters || hasPluginContributes
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


}
