import Foundation
import SwiftUI
import UniformTypeIdentifiers
import DesignSystem

public class PluginManager: ObservableObject, PluginManaging {
    typealias ShellCommandRunner = (_ command: String, _ cwd: String?) -> (Bool, String)
    typealias DownloadHandler = (_ url: URL, _ destinationURL: URL, _ completion: @escaping (Result<Void, Error>) -> Void) -> Void
    typealias InstallSideEffectHandler = (_ entry: PluginEntry) -> Void

    public static let shared = PluginManager()

    @Published public var plugins: [PluginEntry] = []
    @Published public var isInstalling: Bool = false
    @Published public var installProgress: String = ""
    @Published public var lastError: String?

    // 업데이트 감지
    @Published public var updatablePlugins: [String: String] = [:]   // pluginID → newVersion
    @Published public var isCheckingUpdates: Bool = false

    // 마켓플레이스 검색/필터
    @Published public var searchQuery: String = ""
    @Published public var selectedTags: Set<String> = []
    @Published public var marketplaceCategory: PluginCategory = .all
    @Published public var marketplaceSortOption: PluginSortOption = .popular

    // 디버그 로그
    @Published public var debugLog: [PluginDebugEntry] = []
    let maxDebugEntries = 200

    // 개별 확장 포인트 비활성화 목록 (extensionID set)
    @Published public var disabledExtensions: Set<String> = []
    private let disabledExtensionsKey = "DofficeDisabledExtensions"

    // 플러그인 권한 (신뢰된 플러그인 목록)
    @Published public var trustedPlugins: Set<String> = []   // pluginName set
    private let trustedPluginsKey = "DofficeTrustedPlugins"
    @Published public var pendingPermission: PermissionRequest?

    // 매니페스트 캐시 (detectConflicts 성능 개선)
    /// Manifest cache shared with PluginHost to avoid redundant disk I/O + JSON decoding.
    /// Access must go through the thread-safe helpers below.
    private var _manifestCache: [String: PluginManifest] = [:]  // pluginPath → manifest
    private let manifestCacheQueue = DispatchQueue(label: "com.doffice.manifestCache", attributes: .concurrent)

    func manifestCacheGet(_ key: String) -> PluginManifest? {
        manifestCacheQueue.sync { _manifestCache[key] }
    }

    func manifestCacheSet(_ key: String, _ value: PluginManifest) {
        manifestCacheQueue.async(flags: .barrier) { self._manifestCache[key] = value }
    }

    func manifestCacheClear() {
        manifestCacheQueue.async(flags: .barrier) { self._manifestCache.removeAll() }
    }

    // 충돌 감지 캐시 (pluginRow마다 재계산 방지)
    @Published public var cachedConflicts: [PluginConflict] = []

    // 핫 리로드
    var fileWatchers: [String: DispatchSourceFileSystemObject] = [:]

    // 마켓플레이스
    @Published public var registryPlugins: [RegistryPlugin] = []
    @Published public var isLoadingRegistry: Bool = false
    @Published public var registryError: String?

    let storageKey = "DofficePlugins"
    let pluginBaseDir: URL
    let userDefaults: UserDefaults
    let shellCommandRunner: ShellCommandRunner
    let downloadHandler: DownloadHandler
    let installSideEffectHandler: InstallSideEffectHandler

    /// 레지스트리 URL — GitHub Pages 또는 raw 파일
    /// 기여자는 이 저장소에 PR로 registry.json에 자기 플러그인을 추가
    public static let registryURL = "https://raw.githubusercontent.com/jjunhaa0211/Doffice/main/registry.json"

    init(
        pluginBaseDir: URL = PluginManager.defaultPluginBaseDir(),
        userDefaults: UserDefaults = .standard,
        shellCommandRunner: @escaping ShellCommandRunner = PluginManager.defaultShellCommandRunner,
        downloadHandler: @escaping DownloadHandler = PluginManager.defaultDownloadHandler,
        installSideEffectHandler: @escaping InstallSideEffectHandler = PluginManager.defaultInstallSideEffectHandler
    ) {
        self.pluginBaseDir = pluginBaseDir
        self.userDefaults = userDefaults
        self.shellCommandRunner = shellCommandRunner
        self.downloadHandler = downloadHandler
        self.installSideEffectHandler = installSideEffectHandler
        do {
            try FileManager.default.createDirectory(at: pluginBaseDir, withIntermediateDirectories: true)
        } catch {
            CrashLogger.shared.error("PluginManager: Failed to create plugin directory \(pluginBaseDir.path) — \(error.localizedDescription)")
        }
        loadPlugins()
    }

    // MARK: - Persistence

    func loadPlugins() {
        if let data = userDefaults.data(forKey: storageKey) {
            do {
                plugins = try JSONDecoder().decode([PluginEntry].self, from: data)
            } catch {
                CrashLogger.shared.error("PluginManager: Failed to decode saved plugins — \(error.localizedDescription). Starting with empty list.")
                plugins = []
            }
        } else {
            plugins = []
        }
        loadDisabledExtensions()
        loadTrustedPlugins()
    }

    func loadDisabledExtensions() {
        if let arr = userDefaults.stringArray(forKey: disabledExtensionsKey) {
            disabledExtensions = Set(arr)
        }
    }

    func saveDisabledExtensions() {
        userDefaults.set(Array(disabledExtensions), forKey: disabledExtensionsKey)
    }

    /// 개별 확장 포인트 활성/비활성 토글
    public func toggleExtension(_ extensionId: String) {
        if disabledExtensions.contains(extensionId) {
            disabledExtensions.remove(extensionId)
        } else {
            disabledExtensions.insert(extensionId)
        }
        saveDisabledExtensions()
        PluginHost.shared.reload()
    }

    /// 확장 포인트가 활성화되어 있는지 확인
    public func isExtensionEnabled(_ extensionId: String) -> Bool {
        !disabledExtensions.contains(extensionId)
    }

    // MARK: - 플러그인 권한 시스템

    public struct PermissionRequest: Identifiable {
        public let id = UUID()
        public let pluginName: String
        public let scriptPath: String
        public let onAllow: () -> Void
        public let onDeny: () -> Void
    }

    func loadTrustedPlugins() {
        if let arr = userDefaults.stringArray(forKey: trustedPluginsKey) {
            trustedPlugins = Set(arr)
        }
    }

    func saveTrustedPlugins() {
        userDefaults.set(Array(trustedPlugins), forKey: trustedPluginsKey)
    }

    /// 플러그인을 신뢰 목록에 추가
    public func trustPlugin(_ pluginName: String) {
        trustedPlugins.insert(pluginName)
        saveTrustedPlugins()
    }

    /// 플러그인 신뢰 해제
    public func untrustPlugin(_ pluginName: String) {
        trustedPlugins.remove(pluginName)
        saveTrustedPlugins()
    }

    /// 플러그인이 신뢰된 상태인지 확인
    public func isPluginTrusted(_ pluginName: String) -> Bool {
        trustedPlugins.contains(pluginName)
    }

    /// 스크립트 실행 전 권한 확인 (신뢰된 플러그인이면 바로 실행, 아니면 요청)
    public func requestPermission(pluginName: String, scriptPath: String, onAllow: @escaping () -> Void, onDeny: @escaping () -> Void = {}) {
        if isPluginTrusted(pluginName) {
            onAllow()
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.pendingPermission = PermissionRequest(
                pluginName: pluginName,
                scriptPath: scriptPath,
                onAllow: onAllow,
                onDeny: onDeny
            )
        }
    }

    /// 권한 요청 승인
    public func approvePermission(alwaysTrust: Bool = false) {
        guard let req = pendingPermission else { return }
        if alwaysTrust {
            trustPlugin(req.pluginName)
        }
        req.onAllow()
        pendingPermission = nil
    }

    /// 권한 요청 거부
    public func denyPermission() {
        pendingPermission?.onDeny()
        pendingPermission = nil
    }

    func savePlugins() {
        do {
            let data = try JSONEncoder().encode(plugins)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            CrashLogger.shared.error("PluginManager: Failed to encode plugins for save — \(error.localizedDescription). Plugin state may be lost.")
        }
        manifestCacheClear()
    }

}
