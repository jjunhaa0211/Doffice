import Foundation
import SwiftUI
import DesignSystem

extension PluginManager {

    // MARK: - 활성 플러그인 경로 목록 (세션에 주입)

    public var activePluginPaths: [String] {
        plugins.compactMap { plugin in
            guard plugin.enabled else { return nil }

            if let bundledID = Self.bundledPluginID(from: plugin.source),
               let bundledPath = Self.resolvedBundledRuntimePath(id: bundledID) {
                return bundledPath
            }

            guard FileManager.default.fileExists(atPath: plugin.localPath) else { return nil }
            return plugin.localPath
        }
    }

    // MARK: - 마켓플레이스 (레지스트리)

    public func fetchRegistry() {
        isLoadingRegistry = true
        registryError = nil

        guard let url = URL(string: Self.registryURL) else {
            registryPlugins = Self.mergedRegistry(remote: [])
            registryError = nil
            isLoadingRegistry = false
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoadingRegistry = false

                if let error = error {
                    CrashLogger.shared.warning("PluginManager: Registry fetch failed — \(error.localizedDescription)")
                    self.registryError = error.localizedDescription
                } else if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    let msg = "HTTP \(http.statusCode)"
                    CrashLogger.shared.warning("PluginManager: Registry fetch failed — \(msg)")
                    self.registryError = msg
                } else {
                    self.registryError = nil
                }
                let remoteItems = Self.resolveRegistryItems(data: data, response: response, error: error)
                self.registryPlugins = Self.mergedRegistry(remote: remoteItems)
                self.checkForUpdates()
            }
        }.resume()
    }

    /// 레지스트리에서 설치
    public func installFromRegistry(_ item: RegistryPlugin) {
        if let bundledID = Self.bundledPluginID(from: item.downloadURL) {
            installBundledPlugin(item, bundledID: bundledID)
            return
        }

        // plugin.json manifest → 관련 파일 모두 다운로드
        if item.downloadURL.hasSuffix("plugin.json") || item.downloadURL.hasSuffix("package.json") {
            installFromManifestURL(item)
            return
        }

        install(source: item.downloadURL)
    }

    /// plugin.json manifest URL에서 관련 파일 모두 다운로드
    func installFromManifestURL(_ item: RegistryPlugin) {
        guard let manifestURL = URL(string: item.downloadURL) else {
            finishWithError(NSLocalizedString("plugin.error.invalid.url", comment: ""))
            return
        }

        let baseURL = manifestURL.deletingLastPathComponent()
        let pluginDir = pluginBaseDir.appendingPathComponent(item.id)
        let fm = FileManager.default

        isInstalling = true
        lastError = nil
        installProgress = String(format: NSLocalizedString("plugin.progress.downloading", comment: ""), item.name)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // 1) pluginDir 준비
            do {
                if fm.fileExists(atPath: pluginDir.path) {
                    try fm.removeItem(at: pluginDir)
                }
                try fm.createDirectory(at: pluginDir, withIntermediateDirectories: true)
            } catch {
                self.finishWithError(String(format: NSLocalizedString("plugin.error.download.failed", comment: ""), error.localizedDescription))
                return
            }

            // 2) manifest 다운로드 및 파싱
            guard let manifestData = try? Data(contentsOf: manifestURL) else {
                self.cleanupManagedPluginDirectory(pluginDir)
                self.finishWithError(String(format: NSLocalizedString("plugin.error.download.failed", comment: ""), "manifest"))
                return
            }

            let manifestDest = pluginDir.appendingPathComponent(manifestURL.lastPathComponent)
            try? manifestData.write(to: manifestDest)

            // 3) manifest에서 참조하는 파일 목록 추출
            var filesToDownload: [String] = ["characters.json", "README.md", "package.json"]
            if let manifest = try? JSONSerialization.jsonObject(with: manifestData) as? [String: Any] {
                if let contributes = manifest["contributes"] as? [String: Any] {
                    for (_, value) in contributes {
                        if let fileName = value as? String {
                            filesToDownload.append(fileName)
                        }
                    }
                }
                if let files = manifest["files"] as? [String] {
                    filesToDownload.append(contentsOf: files)
                }
            }

            // 중복 제거
            let uniqueFiles = Array(Set(filesToDownload))

            // 4) 각 파일 다운로드 (manifest와 같은 디렉토리에서)
            var failedFiles: [String] = []
            for fileName in uniqueFiles {
                let fileURL = baseURL.appendingPathComponent(fileName)
                let destPath = pluginDir.appendingPathComponent(fileName)
                let parentDir = destPath.deletingLastPathComponent()
                try? fm.createDirectory(at: parentDir, withIntermediateDirectories: true)

                do {
                    let data = try Data(contentsOf: fileURL)
                    try data.write(to: destPath, options: .atomicWrite)
                } catch {
                    CrashLogger.shared.warning("PluginManager: Failed to download/write \(fileName) — \(error.localizedDescription)")
                    failedFiles.append(fileName)
                }
            }
            if !failedFiles.isEmpty {
                CrashLogger.shared.error("PluginManager: \(failedFiles.count) file(s) failed during install: \(failedFiles.joined(separator: ", "))")
            }

            // 5) CLAUDE.md가 없으면 manifest에서 생성
            let claudeMDPath = pluginDir.appendingPathComponent("CLAUDE.md")
            if !fm.fileExists(atPath: claudeMDPath.path) {
                let claudeContent = "# \(item.name)\n\n\(item.description)\n"
                try? claudeContent.write(to: claudeMDPath, atomically: true, encoding: .utf8)
            }

            // 6) validation
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

    /// 이미 설치되어 있는지 확인
    public func isInstalled(_ registryItem: RegistryPlugin) -> Bool {
        plugins.contains { $0.source == registryItem.downloadURL || $0.name == registryItem.name }
    }


}
