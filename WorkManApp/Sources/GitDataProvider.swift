import SwiftUI
import Combine

// ═══════════════════════════════════════════════════════
// MARK: - Git Data Models
// ═══════════════════════════════════════════════════════

struct GitCommitNode: Identifiable, Equatable {
    let id: String            // full SHA
    let shortHash: String
    let message: String
    let body: String          // full message body (for co-authors, etc.)
    let author: String
    let authorEmail: String
    let date: Date
    let parentHashes: [String]
    let coAuthors: [String]
    let refs: [GitRef]
    var lane: Int = 0         // column for graph drawing
    var activeLanes: Set<Int> = [] // which lanes are active at this row (for drawing vertical lines)

    struct GitRef: Equatable {
        let name: String
        let type: RefType
        enum RefType: Equatable { case branch, remoteBranch, tag, head }
    }
}

struct GitFileChange: Identifiable, Hashable {
    let id: String
    let path: String
    let fileName: String
    let status: ChangeStatus
    let isStaged: Bool

    init(path: String, fileName: String, status: ChangeStatus, isStaged: Bool) {
        self.id = "\(isStaged ? "S" : "U")_\(status.rawValue)_\(path)"
        self.path = path
        self.fileName = fileName
        self.status = status
        self.isStaged = isStaged
    }

    enum ChangeStatus: String, Hashable {
        case modified = "M", added = "A", deleted = "D"
        case renamed = "R", copied = "C", untracked = "?"
        case typeChanged = "T"

        var icon: String {
            switch self {
            case .modified: return "pencil.circle.fill"
            case .added: return "plus.circle.fill"
            case .deleted: return "minus.circle.fill"
            case .renamed: return "arrow.right.circle.fill"
            case .copied: return "doc.on.doc.fill"
            case .untracked: return "questionmark.circle.fill"
            case .typeChanged: return "arrow.triangle.2.circlepath"
            }
        }

        var color: Color {
            switch self {
            case .modified: return Theme.yellow
            case .added: return Theme.green
            case .deleted: return Theme.red
            case .renamed: return Theme.cyan
            case .copied: return Theme.accent
            case .untracked: return Theme.textDim
            case .typeChanged: return Theme.orange
            }
        }
    }
}

struct GitBranchInfo: Identifiable {
    var id: String { name }
    let name: String
    let isRemote: Bool
    let isCurrent: Bool
    let upstream: String?
    let ahead: Int
    let behind: Int
}

struct GitStashEntry: Identifiable {
    let id: Int
    let message: String
}

// ═══════════════════════════════════════════════════════
// MARK: - Git Data Provider
// ═══════════════════════════════════════════════════════

@MainActor
class GitDataProvider: ObservableObject {
    @Published var commits: [GitCommitNode] = []
    @Published var workingDirStaged: [GitFileChange] = []
    @Published var workingDirUnstaged: [GitFileChange] = []
    @Published var branches: [GitBranchInfo] = []
    @Published var stashes: [GitStashEntry] = []
    @Published var currentBranch: String = ""
    @Published var isLoading = false
    @Published var selectedCommitFiles: [GitFileChange] = []
    @Published var maxLaneCount: Int = 1

    // Precomputed lookup: SHA → lane (for O(1) parent lane lookup in graph drawing)
    var commitLaneMap: [String: Int] = [:]

    private var projectPath: String = ""
    private var refreshTimer: AnyCancellable?

    // Lane colors — computed each time to respect dark/light mode changes
    static var laneColors: [Color] {
        [Theme.accent, Theme.green, Theme.purple, Theme.orange,
         Theme.cyan, Theme.pink, Theme.yellow, Theme.red]
    }

    func start(projectPath: String) {
        guard !projectPath.isEmpty else { return }
        self.projectPath = projectPath
        refreshAll()
        refreshTimer = Timer.publish(every: 8, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.refreshAll() }
    }

    func stop() {
        refreshTimer?.cancel()
        refreshTimer = nil
    }

    func refreshAll() {
        guard !projectPath.isEmpty, !isLoading else { return }
        isLoading = true
        let path = projectPath
        DispatchQueue.global(qos: .userInitiated).async {
            let commits = GitDataParser.parseCommits(path: path)
            let (staged, unstaged) = GitDataParser.parseWorkingDir(path: path)
            let branches = GitDataParser.parseBranches(path: path)
            let stashes = GitDataParser.parseStashes(path: path)
            let currentBr = TerminalTab.shellSync("git -C \"\(path)\" branch --show-current 2>/dev/null")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let maxLane = (commits.map { $0.lane }.max() ?? 0) + 1
            var laneMap: [String: Int] = [:]
            for c in commits { laneMap[c.id] = c.lane }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.commits = commits
                self.workingDirStaged = staged
                self.workingDirUnstaged = unstaged
                self.branches = branches
                self.stashes = stashes
                self.currentBranch = currentBr
                self.maxLaneCount = maxLane
                self.commitLaneMap = laneMap
                self.isLoading = false
            }
        }
    }

    func fetchCommitFiles(hash: String) {
        // Validate hash is hex-only (prevent command injection)
        guard hash.allSatisfy({ $0.isHexDigit }) else { return }
        let path = projectPath
        DispatchQueue.global(qos: .userInitiated).async {
            let raw = TerminalTab.shellSync("git -C \"\(path)\" diff-tree --no-commit-id --name-status -r \(hash) 2>/dev/null") ?? ""
            let files = raw.components(separatedBy: "\n").compactMap { line -> GitFileChange? in
                let parts = line.split(separator: "\t", maxSplits: 1)
                guard parts.count == 2 else { return nil }
                let statusStr = String(parts[0]).trimmingCharacters(in: .whitespaces)
                let filePath = String(parts[1])
                let status = GitFileChange.ChangeStatus(rawValue: String(statusStr.prefix(1))) ?? .modified
                return GitFileChange(path: filePath, fileName: (filePath as NSString).lastPathComponent, status: status, isStaged: true)
            }
            DispatchQueue.main.async { [weak self] in self?.selectedCommitFiles = files }
        }
    }
}

// ═══════════════════════════════════════════════════════
// MARK: - Git Data Parser (nonisolated, runs on background)
// ═══════════════════════════════════════════════════════

enum GitDataParser {

    private static let gitDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    // MARK: - Commits

    static func parseCommits(path: String, limit: Int = 150) -> [GitCommitNode] {
        // Use %x00 (NUL) as record separator between commits to handle multi-line bodies
        let fieldSep = "<<F>>"
        // Format: hash, shortHash, subject, author, email, date, parents, refs
        // Body is fetched separately per-record to avoid multi-line breakage
        let format = "%x00%H\(fieldSep)%h\(fieldSep)%s\(fieldSep)%an\(fieldSep)%ae\(fieldSep)%aI\(fieldSep)%P\(fieldSep)%D\(fieldSep)%b"
        let raw = TerminalTab.shellSync("git -C \"\(path)\" log --all --topo-order --format='\(format)' -n \(limit) 2>/dev/null") ?? ""

        var commits: [GitCommitNode] = []
        // Split by NUL character to separate commits (handles multi-line bodies)
        let records = raw.components(separatedBy: "\0").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        for record in records {
            let trimmed = record.trimmingCharacters(in: .whitespacesAndNewlines)
            // Find the first field separator to split fields
            let parts = trimmed.components(separatedBy: fieldSep)
            guard parts.count >= 8 else { continue }

            let hash = parts[0].trimmingCharacters(in: .init(charactersIn: "'"))
            let shortHash = parts[1]
            let subject = parts[2]
            let author = parts[3]
            let email = parts[4]
            let dateStr = parts[5]
            let parents = parts[6].split(separator: " ").map(String.init)
            // Everything from parts[7] onward is refs + body (body may contain fieldSep theoretically)
            let refStr = parts[7].trimmingCharacters(in: .init(charactersIn: "'"))
            let body = parts.count > 8 ? parts[8...].joined(separator: fieldSep).trimmingCharacters(in: .whitespacesAndNewlines) : ""

            let date = gitDateFormatter.date(from: dateStr) ?? Date()
            let refs = parseRefs(refStr)
            let coAuthors = parseCoAuthors(body)

            commits.append(GitCommitNode(
                id: hash, shortHash: shortHash, message: subject, body: body,
                author: author, authorEmail: email, date: date,
                parentHashes: parents, coAuthors: coAuthors, refs: refs
            ))
        }

        return assignLanes(commits)
    }

    private static func parseRefs(_ str: String) -> [GitCommitNode.GitRef] {
        guard !str.isEmpty else { return [] }
        return str.components(separatedBy: ", ").compactMap { r in
            let trimmed = r.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("HEAD -> ") {
                return .init(name: String(trimmed.dropFirst(8)), type: .head)
            } else if trimmed.hasPrefix("tag: ") {
                return .init(name: String(trimmed.dropFirst(5)), type: .tag)
            } else if trimmed.contains("/") {
                return .init(name: trimmed, type: .remoteBranch)
            } else if !trimmed.isEmpty && trimmed != "HEAD" {
                return .init(name: trimmed, type: .branch)
            }
            return nil
        }
    }

    private static func parseCoAuthors(_ body: String) -> [String] {
        body.components(separatedBy: "\n")
            .filter { $0.lowercased().contains("co-authored-by:") }
            .compactMap { line in
                let parts = line.components(separatedBy: ":")
                guard parts.count >= 2 else { return nil }
                return parts.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
            }
    }

    // MARK: - Lane Assignment

    private static func assignLanes(_ commits: [GitCommitNode]) -> [GitCommitNode] {
        var result = commits
        var activeLanes: [String?] = [] // SHA expected in each lane

        for i in 0..<result.count {
            let commit = result[i]

            // Find lane where this commit was expected
            var myLane = activeLanes.firstIndex(of: commit.id)

            if myLane == nil {
                if let emptyIdx = activeLanes.firstIndex(of: nil) {
                    myLane = emptyIdx
                } else {
                    myLane = activeLanes.count
                    activeLanes.append(nil)
                }
            }

            result[i].lane = myLane!

            // Record which lanes are active at this position (for graph drawing)
            var activeSet = Set<Int>()
            for (idx, sha) in activeLanes.enumerated() {
                if sha != nil { activeSet.insert(idx) }
            }
            activeSet.insert(myLane!)
            result[i].activeLanes = activeSet

            // Update lanes: replace current lane with first parent, add others
            if commit.parentHashes.isEmpty {
                activeLanes[myLane!] = nil
            } else {
                activeLanes[myLane!] = commit.parentHashes[0]
                for pIdx in commit.parentHashes.indices.dropFirst() {
                    let parentHash = commit.parentHashes[pIdx]
                    if !activeLanes.contains(parentHash) {
                        if let emptyIdx = activeLanes.firstIndex(of: nil) {
                            activeLanes[emptyIdx] = parentHash
                        } else {
                            activeLanes.append(parentHash)
                        }
                    }
                }
            }

            // Collapse trailing nils
            while activeLanes.last == nil && activeLanes.count > 1 { activeLanes.removeLast() }
        }

        return result
    }

    // MARK: - Working Directory

    static func parseWorkingDir(path: String) -> (staged: [GitFileChange], unstaged: [GitFileChange]) {
        let raw = TerminalTab.shellSync("git -C \"\(path)\" status --porcelain 2>/dev/null") ?? ""
        var staged: [GitFileChange] = []
        var unstaged: [GitFileChange] = []

        for line in raw.components(separatedBy: "\n") where line.count >= 3 {
            let indexStatus = line[line.index(line.startIndex, offsetBy: 0)]
            let workStatus = line[line.index(line.startIndex, offsetBy: 1)]
            let filePath = String(line.dropFirst(3))
            let fileName = (filePath as NSString).lastPathComponent

            if indexStatus != " " && indexStatus != "?" {
                let s = GitFileChange.ChangeStatus(rawValue: String(indexStatus)) ?? .modified
                staged.append(GitFileChange(path: filePath, fileName: fileName, status: s, isStaged: true))
            }
            if workStatus != " " || indexStatus == "?" {
                let s: GitFileChange.ChangeStatus = indexStatus == "?" ? .untracked : (GitFileChange.ChangeStatus(rawValue: String(workStatus)) ?? .modified)
                unstaged.append(GitFileChange(path: filePath, fileName: fileName, status: s, isStaged: false))
            }
        }
        return (staged, unstaged)
    }

    // MARK: - Branches

    static func parseBranches(path: String) -> [GitBranchInfo] {
        let raw = TerminalTab.shellSync("git -C \"\(path)\" branch -a --format='%(refname:short)|%(upstream:short)|%(upstream:track)' 2>/dev/null") ?? ""
        let current = TerminalTab.shellSync("git -C \"\(path)\" branch --show-current 2>/dev/null")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return raw.components(separatedBy: "\n").compactMap { line in
            let trimmed = line.trimmingCharacters(in: .init(charactersIn: "'"))
            let parts = trimmed.components(separatedBy: "|")
            guard !parts[0].isEmpty else { return nil }
            let name = parts[0]
            let upstream = parts.count > 1 && !parts[1].isEmpty ? parts[1] : nil
            let isRemote = name.hasPrefix("origin/") || name.contains("/")

            var ahead = 0, behind = 0
            if parts.count > 2 {
                let track = parts[2]
                if let r = track.range(of: "ahead (\\d+)", options: .regularExpression) {
                    ahead = Int(track[r].components(separatedBy: " ").last ?? "") ?? 0
                }
                if let r = track.range(of: "behind (\\d+)", options: .regularExpression) {
                    behind = Int(track[r].components(separatedBy: " ").last ?? "") ?? 0
                }
            }

            return GitBranchInfo(name: name, isRemote: isRemote, isCurrent: name == current, upstream: upstream, ahead: ahead, behind: behind)
        }
    }

    // MARK: - Stashes

    static func parseStashes(path: String) -> [GitStashEntry] {
        let raw = TerminalTab.shellSync("git -C \"\(path)\" stash list --format='%gd|%gs' 2>/dev/null") ?? ""
        return raw.components(separatedBy: "\n").enumerated().compactMap { idx, line in
            let trimmed = line.trimmingCharacters(in: .init(charactersIn: "'"))
            guard !trimmed.isEmpty else { return nil }
            let parts = trimmed.components(separatedBy: "|")
            return GitStashEntry(id: idx, message: parts.count > 1 ? parts[1] : trimmed)
        }
    }
}
