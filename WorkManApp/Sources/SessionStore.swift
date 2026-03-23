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
                summaryTokens: tab.summary?.tokenCount
            )
        }

        let history = SessionHistory(sessions: saved, lastSaved: Date())

        do {
            let data = try JSONEncoder().encode(history)
            try data.write(to: fileURL, options: .atomicWrite)
        } catch {
            print("[WorkMan] Failed to save sessions: \(error)")
        }
    }

    func load() -> [SavedSession] {
        guard let data = try? Data(contentsOf: fileURL),
              let history = try? JSONDecoder().decode(SessionHistory.self, from: data) else {
            return []
        }
        return history.sessions
    }

    func loadLastSaved() -> Date? {
        guard let data = try? Data(contentsOf: fileURL),
              let history = try? JSONDecoder().decode(SessionHistory.self, from: data) else {
            return nil
        }
        return history.lastSaved
    }

    private func colorToHex(_ color: Color) -> String {
        // Simple mapping based on known theme colors
        let nsColor = NSColor(color)
        let r = Int(nsColor.redComponent * 255)
        let g = Int(nsColor.greenComponent * 255)
        let b = Int(nsColor.blueComponent * 255)
        return String(format: "%02x%02x%02x", r, g, b)
    }
}
