import SwiftUI
import DesignSystem

extension GitPanelView {
    // ═══════════════════════════════════════════════════════
    // MARK: - Right Panel
    // ═══════════════════════════════════════════════════════

    var rightPanel: some View {
        VStack(spacing: 0) {
            if showBlameView {
                blameViewPanel
            } else if showFileHistory {
                fileHistoryPanel
            } else if showDiffViewer, let file = selectedFileForDiff {
                // Diff viewer mode
                diffViewerPanel(file: file)
            } else if let cid = selectedCommitId, let commit = git.commits.first(where: { $0.id == cid }) {
                // Commit selected — show tabs
                commitRightPanel(commit)
            } else {
                // Working directory mode
                workingDirectoryDetail
            }
        }
        .background(Theme.bgCard)
    }

    // MARK: - Commit Right Panel (Tabs: Changes / Info)

    func commitRightPanel(_ commit: GitCommitNode) -> some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                commitRightTabButton(NSLocalizedString("git.changes", comment: ""), tab: .changes, icon: "doc.text.fill")
                commitRightTabButton(NSLocalizedString("git.info", comment: ""), tab: .info, icon: "info.circle.fill")
                Spacer()
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Theme.bgCard)
            Rectangle().fill(Theme.border).frame(height: 1)

            switch rightTab {
            case .changes:
                commitChangesTab(commit)
            case .info:
                commitInfoTab(commit)
            default:
                commitChangesTab(commit)
            }
        }
    }

    func commitRightTabButton(_ label: String, tab: RightPanelTab, icon: String) -> some View {
        let selected = rightTab == tab
        return Button(action: { withAnimation(.easeInOut(duration: 0.15)) { rightTab = tab } }) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: Theme.iconSize(8)))
                Text(label).font(Theme.chrome(8, weight: selected ? .bold : .regular))
            }
            .foregroundColor(selected ? Theme.accent : Theme.textDim)
            .padding(.horizontal, 8).padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 5).fill(selected ? Theme.accent.opacity(0.1) : .clear))
        }.buttonStyle(.plain)
    }

    // MARK: - Commit Changes Tab

    func commitChangesTab(_ commit: GitCommitNode) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                // Commit header
                HStack(spacing: 6) {
                    Text(commit.shortHash)
                        .font(Theme.mono(9, weight: .bold))
                        .foregroundStyle(Theme.accentBackground)
                    Text(commit.message)
                        .font(Theme.mono(9))
                        .foregroundColor(Theme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6).fill(Theme.bgSurface))

                if git.selectedCommitFiles.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 6) {
                            ProgressView().scaleEffect(0.7)
                            Text(NSLocalizedString("git.loading.files", comment: ""))
                                .font(Theme.mono(8))
                                .foregroundColor(Theme.textDim)
                        }
                        .padding(.vertical, 20)
                        Spacer()
                    }
                } else {
                    sectionHeader(NSLocalizedString("git.changed.files", comment: ""), count: git.selectedCommitFiles.count, icon: "doc.text.fill", color: Theme.textSecondary)

                    ForEach(git.selectedCommitFiles) { f in
                        Button(action: {
                            selectedFileForDiff = f
                            git.fetchParsedDiff(path: f.path, staged: false, hash: commit.id)
                            showDiffViewer = true
                        }) {
                            fileChangeRow(f, showDiffArrow: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(10)
        }
    }

    // MARK: - Commit Info Tab

    func commitInfoTab(_ commit: GitCommitNode) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                // Commit message card
                VStack(alignment: .leading, spacing: 6) {
                    Text(commit.message)
                        .font(Theme.mono(12, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    if !commit.body.isEmpty {
                        let clean = commit.body.components(separatedBy: "\n")
                            .filter { !$0.lowercased().contains("co-authored-by") }
                            .joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                        if !clean.isEmpty {
                            Text(clean).font(Theme.mono(9)).foregroundColor(Theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface))

                // Metadata
                VStack(spacing: 5) {
                    metaRow(NSLocalizedString("git.meta.commit", comment: ""), commit.shortHash, mono: true, copyValue: commit.id)
                    if !commit.parentHashes.isEmpty {
                        metaRow(NSLocalizedString("git.meta.parent", comment: ""), commit.parentHashes.map { String($0.prefix(7)) }.joined(separator: " ← "), mono: true)
                    }
                    metaRow(NSLocalizedString("git.meta.author", comment: ""), commit.author)
                    metaRow(NSLocalizedString("git.meta.date", comment: ""), Self.formatDate(commit.date))
                    if !commit.coAuthors.isEmpty {
                        metaRow(NSLocalizedString("git.meta.coauthor", comment: ""), commit.coAuthors.joined(separator: "\n"))
                    }

                    if !commit.refs.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Text(NSLocalizedString("git.meta.refs", comment: "")).font(Theme.mono(8, weight: .bold)).foregroundColor(Theme.textDim)
                                .frame(width: 52, alignment: .trailing)
                            FlowLayout(spacing: 4) {
                                ForEach(commit.refs, id: \.name) { r in refBadge(r) }
                            }
                        }
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface))
            }
            .padding(10)
        }
    }

    // MARK: - Working Directory Detail

    var workingDirectoryDetail: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "folder.badge.gearshape")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.accentBackground)
                Text(NSLocalizedString("git.working.directory", comment: ""))
                    .font(Theme.chrome(9, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text(String(format: NSLocalizedString("git.changes.total", comment: ""), git.workingDirStaged.count + git.workingDirUnstaged.count))
                    .font(Theme.mono(8))
                    .foregroundColor(Theme.textDim)
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(Theme.bgCard)
            Rectangle().fill(Theme.border).frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    // Staged files section
                    if !git.workingDirStaged.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                sectionHeader(NSLocalizedString("git.staged", comment: ""), count: git.workingDirStaged.count, icon: "checkmark.circle.fill", color: Theme.green)
                                Spacer()

                                // Select All / Deselect All toggle
                                Button(action: {
                                    toggleCommitSelection(paths: stagedPaths)
                                }) {
                                    Text(stagedPaths.isSubset(of: selectedCommitPaths) && !stagedPaths.isEmpty ? NSLocalizedString("git.deselect.all", comment: "") : NSLocalizedString("git.select.all", comment: ""))
                                        .font(Theme.mono(7, weight: .bold))
                                        .foregroundStyle(Theme.accentBackground)
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(RoundedRectangle(cornerRadius: 4).fill(Theme.accent.opacity(0.08)))
                                }
                                .buttonStyle(.plain)

                                Button(action: { git.unstageAll(); showInfoToast(NSLocalizedString("git.unstaged.all", comment: "")) }) {
                                    Text(NSLocalizedString("git.unstage.all", comment: ""))
                                        .font(Theme.mono(7, weight: .bold))
                                        .foregroundColor(Theme.orange)
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(RoundedRectangle(cornerRadius: 4).fill(Theme.orange.opacity(0.08)))
                                }
                                .buttonStyle(.plain)
                                .disabled(git.isCommitting)
                            }

                            // Selection count indicator
                            if selectedCommitCount > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.square.fill")
                                        .font(.system(size: 8))
                                        .foregroundStyle(Theme.accentBackground)
                                    Text(String(format: NSLocalizedString("git.files.selected", comment: ""), selectedCommitCount, pendingFileCount))
                                        .font(Theme.mono(8))
                                        .foregroundStyle(Theme.accentBackground)
                                }
                                .padding(.horizontal, 4)
                            }

                            ForEach(git.workingDirStaged) { f in
                                HStack(spacing: 0) {
                                    // Selection checkbox
                                    Button(action: {
                                        toggleCommitSelection(f.path)
                                    }) {
                                        Image(systemName: selectedCommitPaths.contains(f.path) ? "checkmark.square.fill" : "square")
                                            .font(.system(size: 11))
                                            .foregroundColor(selectedCommitPaths.contains(f.path) ? Theme.accent : Theme.textDim)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.leading, 6)
                                    .padding(.trailing, 2)

                                    Button(action: {
                                        selectedFileForDiff = f
                                        git.fetchParsedDiff(path: f.path, staged: true)
                                        showDiffViewer = true
                                    }) {
                                        fileChangeRow(f, showDiffArrow: true)
                                    }
                                    .buttonStyle(.plain)

                                    Button(action: { git.unstageFile(path: f.path); showInfoToast(String(format: NSLocalizedString("git.unstaged.file", comment: ""), f.fileName)) }) {
                                        Text(NSLocalizedString("git.unstage", comment: ""))
                                            .font(Theme.mono(7, weight: .bold))
                                            .foregroundColor(Theme.orange)
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(RoundedRectangle(cornerRadius: 4).fill(Theme.orange.opacity(0.08)))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(git.isCommitting)
                                    .padding(.trailing, 6)
                                }
                            }
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface))
                    }

                    // Unstaged files section
                    if !git.workingDirUnstaged.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                sectionHeader(NSLocalizedString("git.changes", comment: ""), count: git.workingDirUnstaged.count, icon: "pencil.circle.fill", color: Theme.orange)
                                Spacer()
                                if !unstagedOnlyChanges.isEmpty {
                                    Button(action: {
                                        toggleCommitSelection(paths: Set(unstagedOnlyChanges.map(\.path)))
                                    }) {
                                        Text(Set(unstagedOnlyChanges.map(\.path)).isSubset(of: selectedCommitPaths) ? NSLocalizedString("git.deselect.all", comment: "") : NSLocalizedString("git.select.all", comment: ""))
                                            .font(Theme.mono(7, weight: .bold))
                                            .foregroundStyle(Theme.accentBackground)
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(RoundedRectangle(cornerRadius: 4).fill(Theme.accent.opacity(0.08)))
                                    }
                                    .buttonStyle(.plain)
                                }
                                Button(action: { git.stageAll(); showSuccessToast(NSLocalizedString("git.staged.all", comment: "")) }) {
                                    Text(NSLocalizedString("git.stage.all", comment: ""))
                                        .font(Theme.mono(7, weight: .bold))
                                        .foregroundColor(Theme.green)
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(RoundedRectangle(cornerRadius: 4).fill(Theme.green.opacity(0.08)))
                                }
                                .buttonStyle(.plain)
                                .disabled(git.isCommitting)
                            }

                            ForEach(git.workingDirUnstaged) { f in
                                let alreadyStaged = stagedPaths.contains(f.path)
                                HStack(spacing: 0) {
                                    if alreadyStaged {
                                        Text("INDEX")
                                            .font(Theme.mono(6, weight: .bold))
                                            .foregroundColor(Theme.green)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(RoundedRectangle(cornerRadius: 4).fill(Theme.green.opacity(0.08)))
                                            .padding(.leading, 6)
                                            .padding(.trailing, 2)
                                    } else {
                                        Button(action: {
                                            toggleCommitSelection(f.path)
                                        }) {
                                            Image(systemName: selectedCommitPaths.contains(f.path) ? "checkmark.square.fill" : "square")
                                                .font(.system(size: 11))
                                                .foregroundColor(selectedCommitPaths.contains(f.path) ? Theme.accent : Theme.textDim)
                                        }
                                        .buttonStyle(.plain)
                                        .padding(.leading, 6)
                                        .padding(.trailing, 2)
                                    }

                                    Button(action: {
                                        selectedFileForDiff = f
                                        git.fetchParsedDiff(path: f.path, staged: false)
                                        showDiffViewer = true
                                    }) {
                                        fileChangeRow(f, showDiffArrow: true)
                                    }
                                    .buttonStyle(.plain)

                                    Button(action: { git.stageFile(path: f.path); showSuccessToast(String(format: NSLocalizedString("git.staged.file", comment: ""), f.fileName)) }) {
                                        Text(NSLocalizedString("git.stage", comment: ""))
                                            .font(Theme.mono(7, weight: .bold))
                                            .foregroundColor(Theme.green)
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(RoundedRectangle(cornerRadius: 4).fill(Theme.green.opacity(0.08)))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(git.isCommitting)
                                    .padding(.trailing, 2)

                                    Button(action: {
                                        fileToDiscard = f
                                        showDiscardAlert = true
                                    }) {
                                        Text(NSLocalizedString("git.discard", comment: ""))
                                            .font(Theme.mono(7, weight: .bold))
                                            .foregroundColor(Theme.red)
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(RoundedRectangle(cornerRadius: 4).fill(Theme.red.opacity(0.08))
                                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.red.opacity(0.15), lineWidth: 0.5)))
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.trailing, 6)
                                }
                            }

                            if !unstagedOnlyChanges.isEmpty {
                                Text(NSLocalizedString("git.auto.stage.hint", comment: ""))
                                    .font(Theme.mono(7))
                                    .foregroundColor(Theme.textDim)
                                    .padding(.horizontal, 4)
                            }
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface))
                    }

                    // Inline commit box
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Theme.green)
                            Text(NSLocalizedString("git.commit.message", comment: ""))
                                .font(Theme.chrome(9, weight: .bold))
                                .foregroundColor(Theme.textSecondary)
                        }

                        TextEditor(text: $commitMessage)
                            .font(Theme.mono(9))
                            .foregroundColor(Theme.textPrimary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 60, maxHeight: 120)
                            .padding(6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Theme.bgSurface))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))

                        HStack {
                            if selectedCommitCount > 0 {
                                Text(String(format: NSLocalizedString("git.files.selected", comment: ""), selectedCommitCount, pendingFileCount))
                                    .font(Theme.mono(8))
                                    .foregroundStyle(Theme.accentBackground)
                            } else if git.workingDirStaged.isEmpty {
                                Text(NSLocalizedString("git.select.or.stage.hint", comment: ""))
                                    .font(Theme.mono(8))
                                    .foregroundColor(Theme.textDim)
                            }
                            Spacer()
                            if selectedUnstagedOnlyCount > 0 {
                                Text(String(format: NSLocalizedString("git.auto.stage.count", comment: ""), selectedUnstagedOnlyCount))
                                    .font(Theme.mono(7, weight: .bold))
                                    .foregroundColor(Theme.orange)
                                    .padding(.horizontal, 6).padding(.vertical, 3)
                                    .background(Capsule().fill(Theme.orange.opacity(0.1)))
                            }
                            Button(action: {
                                performDirectCommit()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 9))
                                    Text(selectedCommitCount > 0 ? NSLocalizedString("git.commit.selected", comment: "") : NSLocalizedString("git.commit", comment: ""))
                                        .font(Theme.chrome(9, weight: .bold))
                                }
                                .foregroundColor(Theme.textOnAccent)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 6).fill(
                                    canRunDirectCommit ? Theme.green : Theme.green.opacity(0.3)
                                ))
                            }
                            .buttonStyle(.plain)
                            .disabled(!canRunDirectCommit)

                            // Amend button
                            Button(action: { showAmendAlert = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.system(size: 9))
                                    Text("Amend")
                                        .font(Theme.chrome(9, weight: .bold))
                                }
                                .foregroundColor(Theme.yellow)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Theme.yellow.opacity(0.1))
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.yellow.opacity(0.2), lineWidth: 0.5)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface))

                    // Stash section
                    if !git.stashes.isEmpty {
                        stashSection
                    }

                    // Quick actions
                    quickActionGrid
                }
                .padding(10)
            }
        }
    }

    // ═══════════════════════════════════════════════════════
    // MARK: - Diff Viewer
    // ═══════════════════════════════════════════════════════

    func diffViewerPanel(file: GitFileChange) -> some View {
        VStack(spacing: 0) {
            // Diff header
            HStack(spacing: 8) {
                Button(action: {
                    showDiffViewer = false
                    selectedFileForDiff = nil
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.textDim)
                }
                .buttonStyle(.plain)

                Image(systemName: file.status.icon)
                    .font(.system(size: 9))
                    .foregroundColor(file.status.color)
                Text(file.fileName)
                    .font(Theme.mono(9, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                Text(file.path)
                    .font(Theme.mono(7))
                    .foregroundColor(Theme.textDim)
                    .lineLimit(1)
                Spacer()

                Button(action: {
                    git.fetchBlame(filePath: file.path)
                    showBlameView = true
                    showDiffViewer = false
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "person.text.rectangle").font(.system(size: 7))
                        Text("Blame").font(Theme.mono(7, weight: .bold))
                    }
                    .foregroundColor(Theme.purple)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Theme.purple.opacity(0.1)))
                }
                .buttonStyle(.plain)

                Button(action: {
                    git.fetchFileHistory(filePath: file.path)
                    fileHistoryFile = file
                    showFileHistory = true
                    showDiffViewer = false
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "clock.arrow.circlepath").font(.system(size: 7))
                        Text(NSLocalizedString("git.file.history.short", comment: "")).font(Theme.mono(7, weight: .bold))
                    }
                    .foregroundColor(Theme.cyan)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Theme.cyan.opacity(0.1)))
                }
                .buttonStyle(.plain)

                Text(NSLocalizedString("git.unified.view", comment: ""))
                    .font(Theme.mono(7, weight: .bold))
                    .foregroundStyle(Theme.accentBackground)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Theme.accent.opacity(0.1)))
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(Theme.bgCard)
            Rectangle().fill(Theme.border).frame(height: 1)

            // Diff content
            if let diff = git.diffResult {
                if diff.isBinary {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.zipper")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.textDim.opacity(0.4))
                        Text(NSLocalizedString("git.binary.file", comment: ""))
                            .font(Theme.mono(10, weight: .medium))
                            .foregroundColor(Theme.textDim)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if diff.hunks.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.textDim.opacity(0.4))
                        Text(NSLocalizedString("git.no.changes", comment: ""))
                            .font(Theme.mono(10))
                            .foregroundColor(Theme.textDim)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView([.horizontal, .vertical]) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(diff.hunks.enumerated()), id: \.offset) { hunkIdx, hunk in
                                // Hunk header
                                HStack(spacing: 0) {
                                    Text(hunk.header)
                                        .font(Theme.mono(8, weight: .medium))
                                        .foregroundColor(Theme.purple)
                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                    Spacer()
                                }
                                .background(Theme.purple.opacity(0.06))
                                .overlay(alignment: .bottom) {
                                    Rectangle().fill(Theme.purple.opacity(0.15)).frame(height: 0.5)
                                }

                                // Lines
                                ForEach(Array(hunk.lines.enumerated()), id: \.offset) { lineIdx, line in
                                    diffLineView(line)
                                }

                                if hunkIdx < diff.hunks.count - 1 {
                                    Rectangle().fill(Theme.border.opacity(0.3)).frame(height: 1)
                                        .padding(.vertical, 2)
                                }
                            }
                        }
                        .frame(minWidth: 400)
                    }
                }
            } else {
                VStack(spacing: 8) {
                    ProgressView().scaleEffect(0.7)
                    Text(NSLocalizedString("git.loading.diff", comment: ""))
                        .font(Theme.mono(8))
                        .foregroundColor(Theme.textDim)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    func diffLineView(_ line: DiffLine) -> some View {
        let bgColor: Color = {
            switch line.type {
            case .addition: return Theme.green.opacity(0.1)
            case .deletion: return Theme.red.opacity(0.1)
            case .context: return .clear
            }
        }()

        let textColor: Color = {
            switch line.type {
            case .addition: return Theme.green
            case .deletion: return Theme.red
            case .context: return Theme.textSecondary
            }
        }()

        let prefix: String = {
            switch line.type {
            case .addition: return "+"
            case .deletion: return "-"
            case .context: return " "
            }
        }()

        return HStack(spacing: 0) {
            // Old line number
            Text(line.oldLineNum.map { "\($0)" } ?? "")
                .font(Theme.mono(7))
                .foregroundColor(Theme.textDim.opacity(0.5))
                .frame(width: 36, alignment: .trailing)
                .padding(.trailing, 4)

            // New line number
            Text(line.newLineNum.map { "\($0)" } ?? "")
                .font(Theme.mono(7))
                .foregroundColor(Theme.textDim.opacity(0.5))
                .frame(width: 36, alignment: .trailing)
                .padding(.trailing, 8)

            // Prefix
            Text(prefix)
                .font(Theme.mono(8, weight: .bold))
                .foregroundColor(textColor)
                .frame(width: 12)

            // Content
            Text(line.content)
                .font(Theme.mono(8))
                .foregroundColor(textColor)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 0.5)
        .background(bgColor)
    }


    // ═══════════════════════════════════════════════════════
    // MARK: - Blame View
    // ═══════════════════════════════════════════════════════

    var blameViewPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Button(action: { showBlameView = false }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.textDim)
                }
                .buttonStyle(.plain)

                Image(systemName: "person.text.rectangle")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Theme.purple)
                Text("Blame")
                    .font(Theme.chrome(10, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text((git.blameFilePath as NSString).lastPathComponent)
                    .font(Theme.mono(8))
                    .foregroundColor(Theme.textDim)
                    .lineLimit(1)
                Spacer()
                Text("\(git.blameLines.count) lines")
                    .font(Theme.mono(7))
                    .foregroundColor(Theme.textDim)
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(Theme.bgCard)
            Rectangle().fill(Theme.border).frame(height: 1)

            if git.blameLines.isEmpty {
                VStack(spacing: 8) {
                    ProgressView().scaleEffect(0.7)
                    Text("Blame 로딩 중...")
                        .font(Theme.mono(8))
                        .foregroundColor(Theme.textDim)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView([.horizontal, .vertical]) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(git.blameLines) { line in
                            blameLineRow(line)
                        }
                    }
                    .frame(minWidth: 500)
                }
            }
        }
    }

    func blameLineRow(_ line: BlameLine) -> some View {
        let isNew = Date().timeIntervalSince(line.date) < 604800 // < 1 week
        return HStack(spacing: 0) {
            // Line number
            Text("\(line.id)")
                .font(Theme.mono(7))
                .foregroundColor(Theme.textDim.opacity(0.5))
                .frame(width: 36, alignment: .trailing)
                .padding(.trailing, 6)

            // Author + hash
            HStack(spacing: 4) {
                Text(line.shortHash)
                    .font(Theme.mono(7, weight: .medium))
                    .foregroundColor(Theme.accent.opacity(0.7))
                Text(line.author)
                    .font(Theme.mono(7))
                    .foregroundColor(isNew ? Theme.green : Theme.textDim)
                    .lineLimit(1)
                    .frame(width: 80, alignment: .leading)
                Text(GitPanelView.relativeDate(line.date))
                    .font(Theme.mono(6))
                    .foregroundColor(Theme.textDim.opacity(0.5))
                    .frame(width: 55, alignment: .trailing)
            }
            .frame(width: 200)
            .padding(.trailing, 8)

            Rectangle().fill(Theme.border.opacity(0.3)).frame(width: 1)
                .padding(.horizontal, 4)

            // Content
            Text(line.content)
                .font(Theme.mono(8))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 1)
        .background(isNew ? Theme.green.opacity(0.03) : .clear)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.borderSubtle.opacity(0.3)).frame(height: 0.5)
        }
    }

    // ═══════════════════════════════════════════════════════
    // MARK: - File History View
    // ═══════════════════════════════════════════════════════

    var fileHistoryPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Button(action: { showFileHistory = false; fileHistoryFile = nil }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.textDim)
                }
                .buttonStyle(.plain)

                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Theme.cyan)
                Text(NSLocalizedString("git.file.history", comment: ""))
                    .font(Theme.chrome(10, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text((git.fileHistoryPath as NSString).lastPathComponent)
                    .font(Theme.mono(8))
                    .foregroundColor(Theme.textDim)
                    .lineLimit(1)
                Spacer()
                Text("\(git.fileHistory.count) commits")
                    .font(Theme.mono(7))
                    .foregroundColor(Theme.textDim)
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(Theme.bgCard)
            Rectangle().fill(Theme.border).frame(height: 1)

            if git.fileHistory.isEmpty {
                VStack(spacing: 8) {
                    ProgressView().scaleEffect(0.7)
                    Text("히스토리 로딩 중...")
                        .font(Theme.mono(8))
                        .foregroundColor(Theme.textDim)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(git.fileHistory) { commit in
                            Button(action: {
                                showFileHistory = false
                                fileHistoryFile = nil
                                selectCommit(commit)
                            }) {
                                fileHistoryRow(commit)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    func fileHistoryRow(_ commit: GitCommitNode) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 6) {
                Text(commit.shortHash)
                    .font(Theme.mono(8, weight: .bold))
                    .foregroundStyle(Theme.accentBackground)
                Text(commit.message)
                    .font(Theme.mono(9, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 8) {
                HStack(spacing: 3) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 7))
                        .foregroundColor(Theme.textDim)
                    Text(commit.author)
                        .font(Theme.mono(7))
                        .foregroundColor(Theme.textSecondary)
                }
                Text(GitPanelView.relativeDate(commit.date))
                    .font(Theme.mono(7))
                    .foregroundColor(Theme.textDim)
                Spacer()
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.borderSubtle).frame(height: 0.5)
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: {
                git.cherryPick(hash: commit.id) { success in
                    if success { showSuccessToast("Cherry-pick 완료: \(commit.shortHash)") }
                    else { showErrorToast("Cherry-pick 실패") }
                }
            }) {
                Label("Cherry-pick", systemImage: "arrow.uturn.down.circle")
            }
            Button(action: {
                git.revertCommit(hash: commit.id) { success in
                    if success { showSuccessToast("Revert 완료: \(commit.shortHash)") }
                    else { showErrorToast("Revert 실패") }
                }
            }) {
                Label(NSLocalizedString("git.revert", comment: ""), systemImage: "arrow.uturn.backward.circle")
            }
        }
    }

}
