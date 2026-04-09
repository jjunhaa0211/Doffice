import Foundation
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
#endif

extension PluginManager {

    // MARK: - 핫 리로드 (로컬 플러그인 파일 변경 감지)

    /// 로컬 플러그인 디렉토리 감시 시작
    public func startWatchingLocalPlugins() {
        stopWatchingAll()

        for plugin in plugins where plugin.sourceType == .local && plugin.enabled {
            watchDirectory(plugin.localPath, pluginId: plugin.id)
        }
    }

    /// 모든 파일 감시 해제
    public func stopWatchingAll() {
        for (_, source) in fileWatchers {
            source.cancel()
        }
        fileWatchers.removeAll()
    }

    func watchDirectory(_ path: String, pluginId: String) {
        #if os(macOS)
        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete],
            queue: DispatchQueue.global(qos: .utility)
        )

        source.setEventHandler {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                PluginHost.shared.reload()
                EventBus.shared.post(.pluginReload)
                EventBus.shared.post(.pluginCharactersChanged)
            }
        }

        source.setCancelHandler { close(fd) }
        source.resume()
        fileWatchers[pluginId] = source
        #endif
    }

    // MARK: - 플러그인 내보내기

    #if os(macOS)
    /// 플러그인을 tar.gz로 내보내기 (NSSavePanel)
    public func exportPlugin(_ plugin: PluginEntry) {
        let panel = NSSavePanel()
        panel.title = NSLocalizedString("plugin.export.panel.title", comment: "")
        panel.nameFieldStringValue = "\(plugin.name)-v\(plugin.version).tar.gz"
        panel.allowedContentTypes = [.archive]

        panel.begin { [weak self] result in
            guard result == .OK, let destURL = panel.url else { return }

            DispatchQueue.global(qos: .userInitiated).async {
                let destPath = self?.shellEscape(destURL.path) ?? ""
                let parentDir = self?.shellEscape(URL(fileURLWithPath: plugin.localPath).deletingLastPathComponent().path) ?? ""
                let dirName = URL(fileURLWithPath: plugin.localPath).lastPathComponent

                let (ok, output) = self?.runShell("tar -czf \(destPath) -C \(parentDir) \(self?.shellEscape(dirName) ?? "")") ?? (false, "")

                DispatchQueue.main.async {
                    if ok {
                        self?.installProgress = String(format: NSLocalizedString("plugin.export.success", comment: ""), destURL.lastPathComponent)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self?.installProgress = ""
                        }
                    } else {
                        self?.lastError = String(format: NSLocalizedString("plugin.export.failed", comment: ""), output)
                    }
                }
            }
        }
    }
    #endif

    // MARK: - 소스 타입 자동 감지

    public func detectSourceType(_ input: String) -> PluginEntry.SourceType {
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


}
