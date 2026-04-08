import SwiftUI
import Foundation

// ═══════════════════════════════════════════════════════
// MARK: - Auto Update Checker (GitHub Release 직접 다운로드)
// ═══════════════════════════════════════════════════════

class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()

    // 상태
    enum UpdateState: Equatable {
        case idle
        case checking
        case noUpdate
        case available
        case downloading(progress: Double)
        case extracting
        case readyToInstall
        case installing
        case failed(message: String)
    }

    @Published var state: UpdateState = .idle
    @Published var latestVersion: String = ""
    @Published var currentVersion: String = ""
    @Published var releaseNotes: String = ""
    @Published var downloadURL: String = ""

    var hasUpdate: Bool {
        switch state {
        case .available, .downloading, .extracting, .readyToInstall, .failed:
            return !latestVersion.isEmpty && isNewer(latestVersion, than: currentVersion)
        default:
            return false
        }
    }

    var isChecking: Bool { state == .checking }

    // GitHub repo 정보
    private let owner = "jjunhaa0211"
    private let repo = "Doffice"

    private var downloadTask: URLSessionDownloadTask?
    private var downloadDelegate: DownloadDelegate?
    private var downloadSession: URLSession?
    private var downloadedAppURL: URL?

    init() {
        currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    // MARK: - 버전 확인

    func checkForUpdates() {
        // idle, noUpdate, available, failed 상태에서만 체크 허용
        switch state {
        case .idle, .noUpdate, .available, .failed: break
        default: return
        }
        state = .checking

        let urlString = "https://api.github.com/repos/\(owner)/\(repo)/releases/latest"
        guard let url = URL(string: urlString) else {
            state = .idle
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self else { return }

                if let error {
                    print("[도피스] 업데이트 확인 실패: \(error.localizedDescription)")
                    self.state = .failed(message: String(format: NSLocalizedString("update.network.error", comment: ""), error.localizedDescription))
                    return
                }

                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tagName = json["tag_name"] as? String else {
                    self.state = .failed(message: NSLocalizedString("update.parse.error", comment: ""))
                    return
                }

                // draft/prerelease 체크
                let isDraft = json["draft"] as? Bool ?? false
                let isPrerelease = json["prerelease"] as? Bool ?? false
                if isDraft || isPrerelease {
                    self.state = .noUpdate
                    return
                }

                let version = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
                self.latestVersion = version
                self.releaseNotes = json["body"] as? String ?? ""

                // .zip 다운로드 URL 추출 (macOS용)
                self.downloadURL = ""
                if let assets = json["assets"] as? [[String: Any]] {
                    for asset in assets {
                        if let name = asset["name"] as? String,
                           name.hasSuffix(".zip"),
                           let url = asset["browser_download_url"] as? String {
                            self.downloadURL = url
                            break
                        }
                    }
                    // .zip 없으면 .dmg
                    if self.downloadURL.isEmpty {
                        for asset in assets {
                            if let name = asset["name"] as? String,
                               name.hasSuffix(".dmg"),
                               let url = asset["browser_download_url"] as? String {
                                self.downloadURL = url
                                break
                            }
                        }
                    }
                }

                if self.isNewer(version, than: self.currentVersion) {
                    self.state = .available
                    print("[도피스] 업데이트 발견: v\(self.currentVersion) → v\(version)")
                    // 백그라운드 자동 다운로드 시작
                    self.performUpdate()
                } else {
                    self.state = .noUpdate
                    print("[도피스] 최신 버전 사용 중: v\(self.currentVersion)")
                }
            }
        }.resume()
    }

    // MARK: - 다운로드 & 설치

    func performUpdate() {
        guard !downloadURL.isEmpty, let url = URL(string: downloadURL) else {
            state = .failed(message: NSLocalizedString("update.no.download.url", comment: ""))
            return
        }

        state = .downloading(progress: 0)
        downloadedAppURL = nil

        let delegate = DownloadDelegate { [weak self] progress in
            DispatchQueue.main.async {
                self?.state = .downloading(progress: progress)
            }
        } onComplete: { [weak self] tempURL, error in
            DispatchQueue.main.async {
                self?.handleDownloadComplete(tempURL: tempURL, error: error)
            }
        }
        self.downloadDelegate = delegate

        // 이전 세션이 있으면 정리 (URLSession은 delegate를 강하게 참조하므로 반드시 invalidate)
        downloadSession?.invalidateAndCancel()
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        downloadSession = session
        downloadTask = session.downloadTask(with: url)
        downloadTask?.resume()
        print("[도피스] 다운로드 시작: \(downloadURL)")
    }

    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        downloadDelegate = nil
        downloadSession?.invalidateAndCancel()
        downloadSession = nil
        state = .available
    }

    private func handleDownloadComplete(tempURL: URL?, error: Error?) {
        if let error {
            state = .failed(message: String(format: NSLocalizedString("update.download.failed", comment: ""), error.localizedDescription))
            return
        }
        guard let tempURL else {
            state = .failed(message: NSLocalizedString("update.file.not.found", comment: ""))
            return
        }

        state = .extracting
        print("[도피스] 다운로드 완료, 압축 해제 중...")

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = self?.extractAndPrepare(zipURL: tempURL)
            // 다운로드 zip 정리
            try? FileManager.default.removeItem(at: tempURL)
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let appURL):
                    self.downloadedAppURL = appURL
                    self.state = .readyToInstall
                    print("[도피스] 설치 준비 완료: \(appURL.path)")
                case .failure(let error):
                    self.state = .failed(message: String(format: NSLocalizedString("update.extract.failed", comment: ""), error.localizedDescription))
                case .none:
                    self.state = .failed(message: NSLocalizedString("update.unknown.error", comment: ""))
                }
            }
        }
    }

    private func extractAndPrepare(zipURL: URL) -> Result<URL, Error> {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("doffice-update-\(UUID().uuidString)")

        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

            // unzip 실행
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
            proc.arguments = ["-o", "-q", zipURL.path, "-d", tempDir.path]
            try proc.run()
            proc.waitUntilExit()

            guard proc.terminationStatus == 0 else {
                return .failure(NSError(domain: "UpdateChecker", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "unzip 종료 코드: \(proc.terminationStatus)"
                ]))
            }

            // .app 번들 찾기
            let contents = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            if let app = contents.first(where: { $0.pathExtension == "app" }) {
                return .success(app)
            }

            // 하위 디렉토리에서 찾기
            for dir in contents where dir.hasDirectoryPath {
                let subContents = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
                if let app = subContents.first(where: { $0.pathExtension == "app" }) {
                    return .success(app)
                }
            }

            // .app을 찾지 못했으면 임시 디렉토리 정리
            try? FileManager.default.removeItem(at: tempDir)
            return .failure(NSError(domain: "UpdateChecker", code: 2, userInfo: [
                NSLocalizedDescriptionKey: NSLocalizedString("update.no.app.found", comment: "")
            ]))
        } catch {
            // 실패 시 임시 디렉토리 정리
            try? FileManager.default.removeItem(at: tempDir)
            return .failure(error)
        }
    }

    // MARK: - 설치 (현재 앱 교체 후 재시작)

    func installAndRestart() {
        guard let newAppURL = downloadedAppURL else {
            state = .failed(message: NSLocalizedString("update.install.not.found", comment: ""))
            return
        }

        // 새 앱 번들이 실제로 존재하는지 확인
        guard FileManager.default.fileExists(atPath: newAppURL.appendingPathComponent("Contents/MacOS").path) else {
            state = .failed(message: "다운로드된 앱 번들이 손상되었습니다.")
            return
        }

        state = .installing

        let currentAppURL = Bundle.main.bundleURL
        let pid = ProcessInfo.processInfo.processIdentifier
        let logFile = FileManager.default.temporaryDirectory.appendingPathComponent("doffice-updater.log").path
        let updateTempDir = newAppURL.deletingLastPathComponent().path

        // 설치 스크립트: PID 대기 → 백업 → ditto 복사 → 검증 → 실행 → 정리
        let script = """
        #!/bin/zsh
        set -euo pipefail
        exec > "\(logFile)" 2>&1
        echo "[updater] 시작: $(date)"
        echo "[updater] PID \(pid) 종료 대기..."

        # PID 기반 종료 대기 (최대 30초)
        for i in {1..60}; do
            kill -0 \(pid) 2>/dev/null || break
            sleep 0.5
        done
        sleep 1

        CURRENT="\(currentAppURL.path)"
        NEW="\(newAppURL.path)"
        BACKUP="${CURRENT}.backup"

        echo "[updater] 백업 생성: $BACKUP"
        rm -rf "$BACKUP"
        if ! mv "$CURRENT" "$BACKUP"; then
            echo "[updater] 백업 실패 — 복원 불필요"
            open "$CURRENT"
            exit 1
        fi

        echo "[updater] ditto 복사: $NEW → $CURRENT"
        if ! /usr/bin/ditto "$NEW" "$CURRENT"; then
            echo "[updater] 복사 실패 — 백업에서 복원"
            rm -rf "$CURRENT"
            mv "$BACKUP" "$CURRENT"
            open "$CURRENT"
            exit 1
        fi

        # quarantine 제거
        /usr/bin/xattr -cr "$CURRENT" 2>/dev/null || true

        # 복사된 앱 번들 검증
        if [ ! -d "${CURRENT}/Contents/MacOS" ]; then
            echo "[updater] 앱 번들 검증 실패 — 백업에서 복원"
            rm -rf "$CURRENT"
            mv "$BACKUP" "$CURRENT"
            open "$CURRENT"
            exit 1
        fi

        # LaunchServices에 새 앱 등록 (캐시 갱신)
        /System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f -R -trusted "$CURRENT" 2>/dev/null || true

        echo "[updater] 새 앱 실행"
        open -n "$CURRENT"

        # 정리 (백업 + 임시 다운로드)
        sleep 3
        rm -rf "$BACKUP"
        rm -rf "\(updateTempDir)"
        echo "[updater] 완료: $(date)"
        """

        let scriptURL = FileManager.default.temporaryDirectory.appendingPathComponent("doffice-updater.sh")
        do {
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
            proc.arguments = [scriptURL.path]
            proc.standardOutput = nil
            proc.standardError = nil
            try proc.run()

            // 스크립트가 실행된 것을 확인 후 종료
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                exit(0)
            }
        } catch {
            state = .failed(message: String(format: NSLocalizedString("update.install.script.failed", comment: ""), error.localizedDescription))
        }
    }

    func openReleasePage() {
        if let url = URL(string: "https://github.com/\(owner)/\(repo)/releases/latest") {
            NSWorkspace.shared.open(url)
        }
    }

    func resetState() {
        downloadTask?.cancel()
        downloadTask = nil
        downloadDelegate = nil
        downloadSession?.invalidateAndCancel()
        downloadSession = nil
        downloadedAppURL = nil
        state = .idle
    }

    // MARK: - Version Comparison

    private func isNewer(_ latest: String, than current: String) -> Bool {
        let lParts = latest.split(separator: ".").compactMap { Int($0) }
        let cParts = current.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(lParts.count, cParts.count) {
            let l = i < lParts.count ? lParts[i] : 0
            let c = i < cParts.count ? cParts[i] : 0
            if l > c { return true }
            if l < c { return false }
        }
        return false
    }
}

// MARK: - Download Delegate

private class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    let onProgress: (Double) -> Void
    let onComplete: (URL?, Error?) -> Void

    init(onProgress: @escaping (Double) -> Void, onComplete: @escaping (URL?, Error?) -> Void) {
        self.onProgress = onProgress
        self.onComplete = onComplete
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // 임시 위치에서 안전한 곳으로 복사 (콜백 리턴 후 삭제되므로)
        let dest = FileManager.default.temporaryDirectory.appendingPathComponent("doffice-download-\(UUID().uuidString).zip")
        do {
            try FileManager.default.copyItem(at: location, to: dest)
            session.finishTasksAndInvalidate()
            onComplete(dest, nil)
        } catch {
            session.finishTasksAndInvalidate()
            onComplete(nil, error)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        onProgress(progress)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error, (error as NSError).code != NSURLErrorCancelled {
            session.finishTasksAndInvalidate()
            onComplete(nil, error)
        }
    }
}

// ═══════════════════════════════════════════════════════
// MARK: - Update Sheet UI
// ═══════════════════════════════════════════════════════

struct UpdateSheet: View {
    @ObservedObject var updater = UpdateChecker.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            headerView
            versionCompareView
            releaseNotesView
            stateView
            actionButtons
        }
        .padding(24)
        .frame(width: 440)
        .background(Theme.bgCard.opacity(1))
        .background(.ultraThickMaterial)
    }

    // MARK: - Header

    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(stateColor.opacity(0.1)).frame(width: 56, height: 56)
                Image(systemName: stateIcon)
                    .font(.system(size: Theme.iconSize(26)))
                    .foregroundColor(stateColor)
            }
            Text(stateTitle)
                .font(Theme.mono(14, weight: .bold))
                .foregroundColor(Theme.textPrimary)
        }
    }

    private var stateColor: Color {
        switch updater.state {
        case .available, .noUpdate, .idle, .checking: return Theme.green
        case .downloading, .extracting: return Theme.accent
        case .readyToInstall: return Theme.green
        case .installing: return Theme.purple
        case .failed: return Theme.red
        }
    }

    private var stateIcon: String {
        switch updater.state {
        case .idle, .checking: return "arrow.down.app.fill"
        case .noUpdate: return "checkmark.circle.fill"
        case .available: return "arrow.down.app.fill"
        case .downloading: return "arrow.down.circle"
        case .extracting: return "doc.zipper"
        case .readyToInstall: return "checkmark.seal.fill"
        case .installing: return "gear.badge.checkmark"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    private var stateTitle: String {
        switch updater.state {
        case .idle, .checking: return NSLocalizedString("update.state.checking", comment: "")
        case .noUpdate: return NSLocalizedString("update.state.latest", comment: "")
        case .available: return NSLocalizedString("update.state.available", comment: "")
        case .downloading: return NSLocalizedString("update.state.downloading", comment: "")
        case .extracting: return NSLocalizedString("update.state.extracting", comment: "")
        case .readyToInstall: return NSLocalizedString("update.state.ready", comment: "")
        case .installing: return NSLocalizedString("update.state.installing", comment: "")
        case .failed: return NSLocalizedString("update.state.failed", comment: "")
        }
    }

    // MARK: - Version Compare

    private var versionCompareView: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text(NSLocalizedString("update.label.current", comment: "")).font(Theme.mono(9)).foregroundColor(Theme.textDim)
                Text("v\(updater.currentVersion)")
                    .font(Theme.mono(13, weight: .bold)).foregroundColor(Theme.textSecondary)
            }
            Image(systemName: "arrow.right")
                .font(.system(size: Theme.iconSize(14)))
                .foregroundColor(Theme.green)
            VStack(spacing: 4) {
                Text(NSLocalizedString("update.label.latest", comment: "")).font(Theme.mono(9)).foregroundColor(Theme.textDim)
                Text("v\(updater.latestVersion.isEmpty ? "..." : updater.latestVersion)")
                    .font(Theme.mono(13, weight: .bold)).foregroundColor(Theme.green)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.bgSurface))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.green.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Release Notes

    @ViewBuilder
    private var releaseNotesView: some View {
        if !updater.releaseNotes.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString("update.release.notes", comment: "")).font(Theme.mono(9, weight: .bold)).foregroundColor(Theme.textDim)
                ScrollView {
                    Text(updater.releaseNotes)
                        .font(Theme.mono(10)).foregroundColor(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.frame(maxHeight: 120)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface.opacity(0.5)))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border.opacity(0.3), lineWidth: 0.5))
        }
    }

    // MARK: - State View

    @ViewBuilder
    private var stateView: some View {
        switch updater.state {
        case .checking:
            HStack(spacing: 8) {
                ProgressView().scaleEffect(0.7)
                Text(NSLocalizedString("update.checking.msg", comment: ""))
                    .font(Theme.mono(10)).foregroundColor(Theme.textSecondary)
            }

        case .downloading(let progress):
            VStack(spacing: 6) {
                ProgressView(value: progress)
                    .tint(Theme.accent)
                HStack {
                    Text(NSLocalizedString("update.downloading.msg", comment: ""))
                        .font(Theme.mono(9)).foregroundColor(Theme.textDim)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(Theme.mono(10, weight: .bold)).foregroundStyle(Theme.accentBackground)
                }
            }

        case .extracting:
            HStack(spacing: 8) {
                ProgressView().scaleEffect(0.7)
                Text(NSLocalizedString("update.extracting.msg", comment: ""))
                    .font(Theme.mono(10)).foregroundColor(Theme.textSecondary)
            }

        case .readyToInstall:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: Theme.iconSize(12))).foregroundColor(Theme.green)
                Text(NSLocalizedString("update.ready.msg", comment: ""))
                    .font(Theme.mono(9)).foregroundColor(Theme.green)
            }

        case .installing:
            HStack(spacing: 8) {
                ProgressView().scaleEffect(0.7)
                Text(NSLocalizedString("update.installing.msg", comment: ""))
                    .font(Theme.mono(10)).foregroundColor(Theme.purple)
            }

        case .failed(let message):
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: Theme.iconSize(10))).foregroundColor(Theme.red)
                    Text(message).font(Theme.mono(9)).foregroundColor(Theme.red)
                        .lineLimit(3).fixedSize(horizontal: false, vertical: true)
                }
            }

        default:
            EmptyView()
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        switch updater.state {
        case .available:
            HStack(spacing: 10) {
                Button(action: { dismiss() }) {
                    Text(NSLocalizedString("update.later", comment: "")).font(Theme.mono(10)).foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border.opacity(0.4), lineWidth: 1))
                }.buttonStyle(.plain).keyboardShortcut(.escape)

                Button(action: { updater.openReleasePage() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "safari").font(.system(size: Theme.iconSize(9)))
                        Text(NSLocalizedString("update.manual.download", comment: "")).font(Theme.mono(10))
                    }
                    .foregroundStyle(Theme.accentBackground)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.accent.opacity(0.08)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.accent.opacity(0.3), lineWidth: 1))
                }.buttonStyle(.plain)

                Button(action: { updater.performUpdate() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill").font(.system(size: Theme.iconSize(10)))
                        Text(NSLocalizedString("update.now", comment: "")).font(Theme.mono(10, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.green))
                }.buttonStyle(.plain).keyboardShortcut(.return)
            }

        case .downloading:
            Button(action: { updater.cancelDownload() }) {
                Text(NSLocalizedString("update.cancel", comment: "")).font(Theme.mono(10)).foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border.opacity(0.4), lineWidth: 1))
            }.buttonStyle(.plain)

        case .readyToInstall:
            HStack(spacing: 10) {
                Button(action: { dismiss() }) {
                    Text(NSLocalizedString("update.apply.on.quit", comment: "")).font(Theme.mono(10)).foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border.opacity(0.4), lineWidth: 1))
                }.buttonStyle(.plain)

                Button(action: { updater.installAndRestart() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise").font(.system(size: Theme.iconSize(10)))
                        Text(NSLocalizedString("update.restart.now", comment: "")).font(Theme.mono(10, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.green))
                }.buttonStyle(.plain).keyboardShortcut(.return)
            }

        case .failed:
            HStack(spacing: 10) {
                Button(action: { dismiss() }) {
                    Text(NSLocalizedString("update.close", comment: "")).font(Theme.mono(10)).foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border.opacity(0.4), lineWidth: 1))
                }.buttonStyle(.plain).keyboardShortcut(.escape)

                Button(action: { updater.openReleasePage() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "safari").font(.system(size: Theme.iconSize(9)))
                        Text(NSLocalizedString("update.manual.download", comment: "")).font(Theme.mono(10))
                    }
                    .foregroundStyle(Theme.accentBackground)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.accent.opacity(0.08)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.accent.opacity(0.3), lineWidth: 1))
                }.buttonStyle(.plain)

                Button(action: { updater.checkForUpdates() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise").font(.system(size: Theme.iconSize(10)))
                        Text(NSLocalizedString("update.retry", comment: "")).font(Theme.mono(10, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.accentBackground))
                }.buttonStyle(.plain).keyboardShortcut(.return)
            }

        case .installing:
            Button(action: { dismiss() }) {
                Text(NSLocalizedString("update.close", comment: "")).font(Theme.mono(10)).foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border.opacity(0.4), lineWidth: 1))
            }.buttonStyle(.plain).keyboardShortcut(.escape)

        case .noUpdate:
            Button(action: { dismiss() }) {
                Text(NSLocalizedString("update.ok", comment: "")).font(Theme.mono(10, weight: .bold)).foregroundColor(.white)
                    .padding(.horizontal, 24).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.accentBackground))
            }.buttonStyle(.plain).keyboardShortcut(.return)

        default:
            EmptyView()
        }
    }
}
