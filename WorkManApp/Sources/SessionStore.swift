import Foundation
import SwiftUI
import AppKit

// MARK: - Feature 4: 세션 기록 저장/복원

struct SavedSession: Codable {
    let projectName: String
    let projectPath: String
    let workerName: String
    let workerColorHex: String
    let tokensUsed: Int
    let branch: String?
    let startTime: Date
    let isCompleted: Bool
    let initialPrompt: String?
    // Summary
    let summaryFiles: [String]?
    let summaryDuration: TimeInterval?
    let summaryTokens: Int?
    // 강제 종료 시 복원용
    let wasProcessing: Bool?
    let lastPrompt: String?
}

struct SessionHistory: Codable {
    var sessions: [SavedSession] = []
    var lastSaved: Date = Date()
}

class SessionStore {
    static let shared = SessionStore()

    private let fileURL: URL = {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return FileManager.default.temporaryDirectory.appendingPathComponent("workman_sessions.json")
        }
        let dir = appSupport.appendingPathComponent("WorkMan", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("sessions.json")
    }()
    private let ioQueue = DispatchQueue(label: "workman.session-store", qos: .utility)
    private let stateLock = NSLock()
    private var cachedHistory = SessionHistory()
    private var hasLoadedCache = false
    private var saveWorkItem: DispatchWorkItem?

    var sessionCount: Int {
        snapshot().sessions.count
    }

    func save(tabs: [TerminalTab]) {
        let saved = tabs.map { tab in
            SavedSession(
                projectName: tab.projectName,
                projectPath: tab.projectPath,
                workerName: tab.workerName,
                workerColorHex: colorToHex(tab.workerColor),
                tokensUsed: tab.tokensUsed,
                branch: tab.branch,
                startTime: tab.startTime,
                isCompleted: tab.isCompleted,
                initialPrompt: tab.initialPrompt,
                summaryFiles: tab.summary?.filesModified,
                summaryDuration: tab.summary?.duration,
                summaryTokens: tab.summary?.tokenCount,
                wasProcessing: tab.isProcessing,
                lastPrompt: tab.lastPromptText
            )
        }

        let history = SessionHistory(sessions: saved, lastSaved: Date())
        updateCache(history, postNotification: true)
        scheduleWrite(history)
    }

    func snapshot() -> SessionHistory {
        loadHistory()
    }

    func load() -> [SavedSession] {
        snapshot().sessions
    }

    func loadLastSaved() -> Date? {
        let history = snapshot()
        return history.sessions.isEmpty ? nil : history.lastSaved
    }

    private func colorToHex(_ color: Color) -> String {
        // Simple mapping based on known theme colors
        let nsColor = NSColor(color)
        let r = Int(nsColor.redComponent * 255)
        let g = Int(nsColor.greenComponent * 255)
        let b = Int(nsColor.blueComponent * 255)
        return String(format: "%02x%02x%02x", r, g, b)
    }

    private func loadHistory() -> SessionHistory {
        stateLock.lock()
        if hasLoadedCache {
            let history = cachedHistory
            stateLock.unlock()
            return history
        }
        stateLock.unlock()

        let loadedHistory: SessionHistory
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode(SessionHistory.self, from: data) {
            loadedHistory = decoded
        } else {
            loadedHistory = SessionHistory()
        }

        stateLock.lock()
        cachedHistory = loadedHistory
        hasLoadedCache = true
        let history = cachedHistory
        stateLock.unlock()
        return history
    }

    private func updateCache(_ history: SessionHistory, postNotification: Bool) {
        stateLock.lock()
        cachedHistory = history
        hasLoadedCache = true
        stateLock.unlock()

        guard postNotification else { return }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .workmanSessionStoreDidChange, object: nil)
        }
    }

    private func scheduleWrite(_ history: SessionHistory) {
        saveWorkItem?.cancel()
        let snapshot = history
        let destination = fileURL
        let workItem = DispatchWorkItem {
            do {
                let data = try JSONEncoder().encode(snapshot)
                try data.write(to: destination, options: .atomicWrite)
            } catch {
                print("[WorkMan] Failed to save sessions: \(error)")
            }
        }
        saveWorkItem = workItem
        ioQueue.asyncAfter(deadline: .now() + 0.75, execute: workItem)
    }
}
