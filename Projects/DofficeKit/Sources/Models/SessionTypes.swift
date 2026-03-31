import SwiftUI
import DesignSystem

// ═══════════════════════════════════════════════════════
// MARK: - Session & Task Types
// ═══════════════════════════════════════════════════════

// 파일 변경 추적
public struct FileChangeRecord: Identifiable {
    public let id = UUID()
    public let path: String
    public let fileName: String
    public let action: String // Write, Edit, Read
    public let timestamp: Date
    public var success: Bool = true

    public init(path: String, fileName: String, action: String, timestamp: Date, success: Bool = true) {
        self.path = path; self.fileName = fileName; self.action = action; self.timestamp = timestamp; self.success = success
    }
}

// 프롬프트 히스토리 (되돌리기 기능)
public struct PromptHistoryEntry: Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let promptText: String
    public let gitCommitHashBefore: String?
    public var fileChanges: [FileChangeRecord]
    public var isCompleted: Bool = false

    public init(timestamp: Date, promptText: String, gitCommitHashBefore: String?, fileChanges: [FileChangeRecord] = []) {
        self.timestamp = timestamp
        self.promptText = promptText
        self.gitCommitHashBefore = gitCommitHashBefore
        self.fileChanges = fileChanges
    }
}

public enum ParallelTaskState: String {
    case running
    case completed
    case failed

    public var label: String {
        switch self {
        case .running: return NSLocalizedString("task.status.running", comment: "")
        case .completed: return NSLocalizedString("task.status.completed", comment: "")
        case .failed: return NSLocalizedString("task.status.failed", comment: "")
        }
    }

    public var tint: Color {
        switch self {
        case .running: return Theme.cyan
        case .completed: return Theme.green
        case .failed: return Theme.red
        }
    }
}

public struct ParallelTaskRecord: Identifiable, Equatable {
    public let id: String
    public let label: String
    public let assigneeCharacterId: String
    public var state: ParallelTaskState

    public init(id: String, label: String, assigneeCharacterId: String, state: ParallelTaskState) {
        self.id = id; self.label = label; self.assigneeCharacterId = assigneeCharacterId; self.state = state
    }
}

public enum TabStatusCategory: String, CaseIterable {
    case active
    case processing
    case completed
    case attention
    case idle
}

public struct TabStatusPresentation {
    public let category: TabStatusCategory
    public let label: String
    public let symbol: String
    public let tint: Color
    public let sortPriority: Int

    public init(category: TabStatusCategory, label: String, symbol: String, tint: Color, sortPriority: Int) {
        self.category = category; self.label = label; self.symbol = symbol; self.tint = tint; self.sortPriority = sortPriority
    }
}

public enum WorkflowStageState: String {
    case queued
    case running
    case completed
    case failed
    case skipped

    public var label: String {
        switch self {
        case .queued: return NSLocalizedString("workflow.stage.queued", comment: "")
        case .running: return NSLocalizedString("workflow.stage.running", comment: "")
        case .completed: return NSLocalizedString("workflow.stage.completed", comment: "")
        case .failed: return NSLocalizedString("workflow.stage.failed", comment: "")
        case .skipped: return NSLocalizedString("workflow.stage.skipped", comment: "")
        }
    }

    public var tint: Color {
        switch self {
        case .queued: return Theme.textDim
        case .running: return Theme.cyan
        case .completed: return Theme.green
        case .failed: return Theme.red
        case .skipped: return Theme.textSecondary
        }
    }
}

public struct WorkflowStageRecord: Identifiable, Equatable {
    public let id: String
    public let role: WorkerJob
    public var workerName: String
    public var assigneeCharacterId: String
    public var state: WorkflowStageState
    public var handoffLabel: String
    public var detail: String
    public var updatedAt: Date

    public init(id: String, role: WorkerJob, workerName: String, assigneeCharacterId: String, state: WorkflowStageState, handoffLabel: String, detail: String, updatedAt: Date) {
        self.id = id; self.role = role; self.workerName = workerName; self.assigneeCharacterId = assigneeCharacterId; self.state = state; self.handoffLabel = handoffLabel; self.detail = detail; self.updatedAt = updatedAt
    }
}

public struct GitInfo {
    public var branch = "", changedFiles = 0, lastCommit = "", lastCommitAge = "", isGitRepo = false
    public init(branch: String = "", changedFiles: Int = 0, lastCommit: String = "", lastCommitAge: String = "", isGitRepo: Bool = false) {
        self.branch = branch; self.changedFiles = changedFiles; self.lastCommit = lastCommit; self.lastCommitAge = lastCommitAge; self.isGitRepo = isGitRepo
    }
}
public struct SessionSummary {
    public var filesModified: [String] = [], duration: TimeInterval = 0, tokenCount: Int = 0, cost: Double = 0, lastLines: [String] = [], commandCount: Int = 0, errorCount: Int = 0, timestamp: Date = Date()
    public init(filesModified: [String] = [], duration: TimeInterval = 0, tokenCount: Int = 0, cost: Double = 0, lastLines: [String] = [], commandCount: Int = 0, errorCount: Int = 0, timestamp: Date = Date()) {
        self.filesModified = filesModified; self.duration = duration; self.tokenCount = tokenCount; self.cost = cost; self.lastLines = lastLines; self.commandCount = commandCount; self.errorCount = errorCount; self.timestamp = timestamp
    }
}

public class SessionGroup: ObservableObject, Identifiable {
    public let id: String; @Published public var name: String; @Published public var color: Color; @Published public var tabIds: [String]
    public init(id: String = UUID().uuidString, name: String, color: Color, tabIds: [String] = []) {
        self.id = id; self.name = name; self.color = color; self.tabIds = tabIds
    }
}
