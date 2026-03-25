import SwiftUI

// ═══════════════════════════════════════════════════════
// MARK: - Git Panel View (GitKraken-style)
// ═══════════════════════════════════════════════════════

struct GitPanelView: View {
    @EnvironmentObject var manager: SessionManager
    @StateObject private var git = GitDataProvider()
    @State private var selectedCommitId: String?
    @State private var showActionSheet = false
    @State private var actionType: GitAction = .commit
    @State private var actionInput: String = ""
    @State private var rightTab: RightPanelTab = .detail
    @State private var hoveredCommitId: String?

    enum GitAction: String, CaseIterable {
        case commit = "커밋", push = "푸시", pull = "풀"
        case branch = "브랜치", stash = "스태시"
        case merge = "병합", checkout = "체크아웃"
    }
    enum RightPanelTab { case detail, branches, tags }

    private var activeTab: TerminalTab? { manager.activeTab }
    private var projectPath: String { activeTab?.projectPath ?? "" }

    // Derived: all tags from commits
    private var allTags: [GitCommitNode.GitRef] {
        git.commits.flatMap { c in c.refs.filter { $0.type == .tag } }
    }
    private var localBranches: [GitBranchInfo] { git.branches.filter { !$0.isRemote } }
    private var remoteBranches: [GitBranchInfo] { git.branches.filter { $0.isRemote } }

    var body: some View {
        VStack(spacing: 0) {
            gitToolbar
            Rectangle().fill(Theme.border).frame(height: 1)

            if projectPath.isEmpty {
                emptyState("탭을 선택하세요", icon: "arrow.triangle.branch")
            } else {
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        leftPanel.frame(width: max(geo.size.width * 0.58, 360))
                        Rectangle().fill(Theme.border).frame(width: 1)
                        rightPanel.frame(minWidth: 260)
                    }
                }
            }
        }
        .background(Theme.bg)
        .onAppear { git.start(projectPath: projectPath) }
        .onDisappear { git.stop() }
        .onChange(of: manager.activeTabId) { _, _ in
            git.stop(); selectedCommitId = nil
            if !projectPath.isEmpty { git.start(projectPath: projectPath) }
        }
        .sheet(isPresented: $showActionSheet) { actionSheet }
    }

    // ═══════════════════════════════════════════════════════
    // MARK: - Toolbar
    // ═══════════════════════════════════════════════════════

    private var gitToolbar: some View {
        HStack(spacing: 6) {
            // Branch pill
            HStack(spacing: 5) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: Theme.iconSize(10), weight: .semibold))
                    .foregroundColor(Theme.green)
                Text(git.currentBranch.isEmpty ? "—" : git.currentBranch)
                    .font(Theme.chrome(10, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)

                if let br = git.branches.first(where: { $0.isCurrent }) {
                    if br.ahead > 0 {
                        Text("↑\(br.ahead)").font(Theme.chrome(8, weight: .bold)).foregroundColor(Theme.green)
                    }
                    if br.behind > 0 {
                        Text("↓\(br.behind)").font(Theme.chrome(8, weight: .bold)).foregroundColor(Theme.orange)
                    }
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.green.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.green.opacity(0.15), lineWidth: 0.5)))

            // Stats pills
            if !git.commits.isEmpty {
                statPill(icon: "clock.arrow.circlepath", text: "\(git.commits.count)", color: Theme.textDim)
            }
            if !allTags.isEmpty {
                statPill(icon: "tag.fill", text: "\(allTags.count)", color: Theme.yellow)
            }
            if !git.stashes.isEmpty {
                statPill(icon: "tray.full.fill", text: "\(git.stashes.count)", color: Theme.cyan)
            }

            Spacer()

            // Action buttons
            toolbarActionBtn("커밋", icon: "checkmark.circle.fill", color: Theme.green) {
                actionType = .commit; actionInput = ""; showActionSheet = true
            }
            toolbarActionBtn("푸시", icon: "arrow.up.circle.fill", color: Theme.accent) {
                executeGitAction(.push, input: "")
            }
            toolbarActionBtn("풀", icon: "arrow.down.circle.fill", color: Theme.cyan) {
                executeGitAction(.pull, input: "")
            }

            Rectangle().fill(Theme.border).frame(width: 1, height: 16)

            toolbarActionBtn("브랜치", icon: "arrow.triangle.branch", color: Theme.purple) {
                actionType = .branch; actionInput = ""; showActionSheet = true
            }
            toolbarActionBtn("스태시", icon: "tray.and.arrow.down.fill", color: Theme.yellow) {
                actionType = .stash; actionInput = ""; showActionSheet = true
            }

            Rectangle().fill(Theme.border).frame(width: 1, height: 16)

            Button(action: { git.refreshAll() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: Theme.iconSize(10), weight: .medium))
                    .foregroundColor(Theme.textDim)
                    .rotationEffect(.degrees(git.isLoading ? 360 : 0))
                    .animation(git.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: git.isLoading)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(Theme.bgCard)
    }

    private func statPill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 8, weight: .medium))
            Text(text).font(Theme.chrome(8, weight: .bold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(RoundedRectangle(cornerRadius: 5).fill(color.opacity(0.06)))
    }

    private func toolbarActionBtn(_ label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: Theme.iconSize(8)))
                Text(label).font(Theme.chrome(8, weight: .medium))
            }
            .foregroundColor(color)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 6).fill(color.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.12), lineWidth: 0.5)))
        }.buttonStyle(.plain)
    }

    // ═══════════════════════════════════════════════════════
    // MARK: - Left Panel (Graph + Commits)
    // ═══════════════════════════════════════════════════════

    private var leftPanel: some View {
        VStack(spacing: 0) {
            if !git.workingDirStaged.isEmpty || !git.workingDirUnstaged.isEmpty {
                workingDirectoryBar
                Rectangle().fill(Theme.border).frame(height: 1)
            }

            // Column headers
            HStack(spacing: 0) {
                Text("GRAPH").frame(width: CGFloat(max(git.maxLaneCount, 1)) * 20 + 12, alignment: .center)
                Text("MESSAGE").padding(.leading, 4)
                Spacer()
                Text("AUTHOR").frame(width: 80, alignment: .center)
                Text("DATE").frame(width: 70, alignment: .trailing).padding(.trailing, 12)
            }
            .font(Theme.mono(7, weight: .bold))
            .foregroundColor(Theme.textDim.opacity(0.5))
            .padding(.vertical, 4)
            .background(Theme.bgSurface.opacity(0.3))

            Rectangle().fill(Theme.border.opacity(0.5)).frame(height: 0.5)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(git.commits) { commit in
                        commitRow(commit)
                            .onTapGesture { selectCommit(commit) }
                            .onHover { hovering in hoveredCommitId = hovering ? commit.id : nil }
                    }
                }
            }
        }
    }

    private var workingDirectoryBar: some View {
        Button(action: { selectedCommitId = nil }) {
            HStack(spacing: 0) {
                // WIP node in graph column
                wipNode
                    .frame(width: CGFloat(max(git.maxLaneCount, 1)) * 20 + 12)

                HStack(spacing: 8) {
                    Text("작업 디렉토리")
                        .font(Theme.mono(10, weight: .bold))
                        .foregroundColor(Theme.yellow)

                    if !git.workingDirStaged.isEmpty {
                        badge("\(git.workingDirStaged.count) staged", color: Theme.green)
                    }
                    badge("\(git.workingDirUnstaged.count) 변경", color: Theme.orange)

                    Spacer()

                    Text("\(git.workingDirStaged.count + git.workingDirUnstaged.count) files")
                        .font(Theme.mono(8))
                        .foregroundColor(Theme.textDim)
                        .padding(.trailing, 12)
                }
            }
            .padding(.vertical, 8)
            .background(selectedCommitId == nil ? Theme.yellow.opacity(0.04) : .clear)
            .overlay(alignment: .leading) {
                if selectedCommitId == nil {
                    Rectangle().fill(Theme.yellow).frame(width: 3)
                }
            }
        }.buttonStyle(.plain)
    }

    private var wipNode: some View {
        Canvas { ctx, size in
            let midX = size.width / 2
            let midY = size.height / 2
            let r: CGFloat = 5
            let rect = CGRect(x: midX - r, y: midY - r, width: r * 2, height: r * 2)
            ctx.stroke(Path(ellipseIn: rect), with: .color(Color.orange), style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
        }
        .frame(width: 20, height: 20)
    }

    // MARK: - Commit Row

    private func commitRow(_ commit: GitCommitNode) -> some View {
        let isSelected = selectedCommitId == commit.id
        let isHovered = hoveredCommitId == commit.id
        let graphW = CGFloat(max(git.maxLaneCount, 1)) * 20 + 12
        let hasTag = commit.refs.contains { $0.type == .tag }

        return HStack(spacing: 0) {
            graphColumn(commit: commit).frame(width: graphW, height: 38)

            // Message + refs
            HStack(spacing: 5) {
                ForEach(commit.refs, id: \.name) { ref in refBadge(ref) }
                Text(commit.message)
                    .font(Theme.mono(10, weight: isSelected ? .bold : .regular))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
            }
            .padding(.leading, 4)

            Spacer(minLength: 8)

            // Author
            Text(commit.author)
                .font(Theme.mono(8))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)
                .frame(width: 80, alignment: .center)

            // Date
            Text(Self.relativeDate(commit.date))
                .font(Theme.mono(8))
                .foregroundColor(Theme.textDim)
                .frame(width: 70, alignment: .trailing)
                .padding(.trailing, 12)
        }
        .padding(.vertical, 1)
        .background(
            isSelected ? Theme.accent.opacity(0.1) :
            isHovered ? Theme.accent.opacity(0.03) :
            hasTag ? Theme.yellow.opacity(0.02) : .clear
        )
        .overlay(alignment: .leading) {
            if isSelected {
                Rectangle().fill(Theme.accent).frame(width: 3)
            }
        }
        .contentShape(Rectangle())
    }

    // MARK: - Graph Drawing

    private func graphColumn(commit: GitCommitNode) -> some View {
        let laneColors = GitDataProvider.laneColors
        let colW: CGFloat = 20
        let activeLanes = commit.activeLanes
        let commitLane = commit.lane
        let parentHashes = commit.parentHashes
        let laneMap = git.commitLaneMap
        let isMerge = parentHashes.count > 1
        let hasTag = commit.refs.contains { $0.type == .tag }

        return Canvas { ctx, size in
            let rowH = size.height
            let midY = rowH / 2

            for laneIdx in activeLanes where laneIdx != commitLane {
                let x = CGFloat(laneIdx) * colW + 10
                let color = laneColors[laneIdx % laneColors.count]
                let p = Path { p in p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: rowH)) }
                ctx.stroke(p, with: .color(color.opacity(0.25)), lineWidth: 1.5)
            }

            let nodeX = CGFloat(commitLane) * colW + 10
            let nodeColor = laneColors[commitLane % laneColors.count]

            ctx.stroke(Path { p in p.move(to: CGPoint(x: nodeX, y: 0)); p.addLine(to: CGPoint(x: nodeX, y: midY)) },
                       with: .color(nodeColor.opacity(0.4)), lineWidth: 1.5)
            if !parentHashes.isEmpty {
                ctx.stroke(Path { p in p.move(to: CGPoint(x: nodeX, y: midY)); p.addLine(to: CGPoint(x: nodeX, y: rowH)) },
                           with: .color(nodeColor.opacity(0.4)), lineWidth: 1.5)
            }

            for pIdx in parentHashes.indices.dropFirst() {
                if let parentLane = laneMap[parentHashes[pIdx]] {
                    let parentX = CGFloat(parentLane) * colW + 10
                    let mergeColor = laneColors[parentLane % laneColors.count]
                    let mp = Path { p in
                        p.move(to: CGPoint(x: nodeX, y: midY))
                        p.addCurve(to: CGPoint(x: parentX, y: rowH),
                                   control1: CGPoint(x: nodeX, y: midY + rowH * 0.3),
                                   control2: CGPoint(x: parentX, y: rowH - rowH * 0.3))
                    }
                    ctx.stroke(mp, with: .color(mergeColor.opacity(0.4)), lineWidth: 1.5)
                }
            }

            // Node
            let r: CGFloat = hasTag ? 5 : 4
            let nodeRect = CGRect(x: nodeX - r, y: midY - r, width: r * 2, height: r * 2)
            if hasTag {
                // Diamond for tagged commits
                let diamond = Path { p in
                    p.move(to: CGPoint(x: nodeX, y: midY - r))
                    p.addLine(to: CGPoint(x: nodeX + r, y: midY))
                    p.addLine(to: CGPoint(x: nodeX, y: midY + r))
                    p.addLine(to: CGPoint(x: nodeX - r, y: midY))
                    p.closeSubpath()
                }
                ctx.fill(diamond, with: .color(Color.yellow))
                ctx.stroke(diamond, with: .color(Color.yellow.opacity(0.6)), lineWidth: 1)
            } else {
                ctx.fill(Path(ellipseIn: nodeRect), with: .color(nodeColor))
                if isMerge {
                    let ring = CGRect(x: nodeX - r - 1.5, y: midY - r - 1.5, width: (r + 1.5) * 2, height: (r + 1.5) * 2)
                    ctx.stroke(Path(ellipseIn: ring), with: .color(nodeColor), lineWidth: 1.5)
                }
            }
        }
    }

    // MARK: - Ref Badges

    private func refBadge(_ ref: GitCommitNode.GitRef) -> some View {
        let (bg, fg, icon): (Color, Color, String) = {
            switch ref.type {
            case .head: return (Theme.green, .white, "chevron.right")
            case .branch: return (Theme.accent, .white, "arrow.triangle.branch")
            case .remoteBranch: return (Theme.purple, .white, "cloud.fill")
            case .tag: return (Theme.yellow, Theme.bg, "tag.fill")
            }
        }()

        return HStack(spacing: 2) {
            Image(systemName: icon).font(.system(size: 6, weight: .bold))
            Text(ref.name).font(Theme.mono(7, weight: .bold)).lineLimit(1)
        }
        .foregroundColor(fg)
        .padding(.horizontal, 5).padding(.vertical, 2)
        .background(Capsule().fill(bg.opacity(ref.type == .tag ? 0.85 : 0.75)))
    }

    // ═══════════════════════════════════════════════════════
    // MARK: - Right Panel
    // ═══════════════════════════════════════════════════════

    private var rightPanel: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                rightTabButton("상세", tab: .detail, icon: "doc.text.fill")
                rightTabButton("브랜치", tab: .branches, icon: "arrow.triangle.branch")
                rightTabButton("태그", tab: .tags, icon: "tag.fill")
                Spacer()
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Theme.bgCard)
            Rectangle().fill(Theme.border).frame(height: 1)

            // Content
            switch rightTab {
            case .detail:
                if let cid = selectedCommitId, let commit = git.commits.first(where: { $0.id == cid }) {
                    commitDetailView(commit)
                } else {
                    workingDirectoryDetail
                }
            case .branches: branchesPanel
            case .tags: tagsPanel
            }
        }
        .background(Theme.bgCard)
    }

    private func rightTabButton(_ label: String, tab: RightPanelTab, icon: String) -> some View {
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

    // MARK: - Commit Detail

    private func commitDetailView(_ commit: GitCommitNode) -> some View {
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
                    metaRow("커밋", commit.shortHash, mono: true, copyValue: commit.id)
                    if !commit.parentHashes.isEmpty {
                        metaRow("부모", commit.parentHashes.map { String($0.prefix(7)) }.joined(separator: " ← "), mono: true)
                    }
                    metaRow("작성자", commit.author)
                    metaRow("날짜", Self.formatDate(commit.date))
                    if !commit.coAuthors.isEmpty {
                        metaRow("공동작성", commit.coAuthors.joined(separator: "\n"))
                    }

                    if !commit.refs.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Text("참조").font(Theme.mono(8, weight: .bold)).foregroundColor(Theme.textDim)
                                .frame(width: 52, alignment: .trailing)
                            FlowLayout(spacing: 4) {
                                ForEach(commit.refs, id: \.name) { r in refBadge(r) }
                            }
                        }
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface))

                // Files
                if !git.selectedCommitFiles.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        sectionHeader("파일 변경", count: git.selectedCommitFiles.count, icon: "doc.text.fill", color: Theme.textSecondary)
                        ForEach(git.selectedCommitFiles) { f in fileChangeRow(f) }
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface))
                }
            }
            .padding(10)
        }
    }

    // MARK: - Working Directory Detail

    private var workingDirectoryDetail: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                // Header card
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(Theme.accent.opacity(0.1)).frame(width: 36, height: 36)
                        Image(systemName: "folder.badge.gearshape").font(.system(size: 14)).foregroundColor(Theme.accent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("작업 디렉토리").font(Theme.mono(12, weight: .bold)).foregroundColor(Theme.textPrimary)
                        Text("\(git.workingDirStaged.count + git.workingDirUnstaged.count)개 파일 변경됨")
                            .font(Theme.mono(9)).foregroundColor(Theme.textDim)
                    }
                    Spacer()
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface))

                if !git.workingDirStaged.isEmpty {
                    fileSection("스테이지됨", files: git.workingDirStaged, color: Theme.green, icon: "checkmark.circle.fill")
                }
                if !git.workingDirUnstaged.isEmpty {
                    fileSection("변경사항", files: git.workingDirUnstaged, color: Theme.orange, icon: "pencil.circle.fill")
                }
                if !git.stashes.isEmpty {
                    stashSection
                }
                quickActionGrid
            }
            .padding(10)
        }
    }

    // MARK: - Branches Panel

    private var branchesPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if !localBranches.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        sectionHeader("로컬 브랜치", count: localBranches.count, icon: "arrow.triangle.branch", color: Theme.accent)
                        ForEach(localBranches) { br in branchRow(br) }
                    }
                    .padding(10).background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface))
                }
                if !remoteBranches.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        sectionHeader("리모트 브랜치", count: remoteBranches.count, icon: "cloud.fill", color: Theme.purple)
                        ForEach(remoteBranches) { br in branchRow(br) }
                    }
                    .padding(10).background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface))
                }
            }
            .padding(10)
        }
    }

    private func branchRow(_ br: GitBranchInfo) -> some View {
        HStack(spacing: 8) {
            Image(systemName: br.isCurrent ? "checkmark.circle.fill" : "arrow.triangle.branch")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(br.isCurrent ? Theme.green : (br.isRemote ? Theme.purple : Theme.accent))
                .frame(width: 16)
            Text(br.name)
                .font(Theme.mono(9, weight: br.isCurrent ? .bold : .regular))
                .foregroundColor(br.isCurrent ? Theme.textPrimary : Theme.textSecondary)
                .lineLimit(1)
            Spacer()
            if br.ahead > 0 {
                Text("↑\(br.ahead)").font(Theme.mono(7, weight: .bold)).foregroundColor(Theme.green)
            }
            if br.behind > 0 {
                Text("↓\(br.behind)").font(Theme.mono(7, weight: .bold)).foregroundColor(Theme.orange)
            }
            if !br.isCurrent {
                Button(action: {
                    actionType = .checkout; actionInput = br.name; showActionSheet = true
                }) {
                    Image(systemName: "arrow.uturn.right").font(.system(size: 8)).foregroundColor(Theme.textDim)
                }.buttonStyle(.plain).help("체크아웃")
            }
        }
        .padding(.vertical, 4).padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 5).fill(br.isCurrent ? Theme.green.opacity(0.05) : .clear))
    }

    // MARK: - Tags Panel

    private var tagsPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    sectionHeader("태그 / 버전", count: allTags.count, icon: "tag.fill", color: Theme.yellow)

                    if allTags.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 6) {
                                Image(systemName: "tag.slash").font(.system(size: 20)).foregroundColor(Theme.textDim.opacity(0.3))
                                Text("태그 없음").font(Theme.mono(9)).foregroundColor(Theme.textDim)
                            }
                            .padding(.vertical, 20)
                            Spacer()
                        }
                    } else {
                        ForEach(Array(allTags.enumerated()), id: \.element.name) { idx, tag in
                            let commit = git.commits.first { $0.refs.contains(where: { $0.name == tag.name && $0.type == .tag }) }
                            tagRow(tag: tag, commit: commit, isLatest: idx == 0)
                        }
                    }
                }
                .padding(10).background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface))
            }
            .padding(10)
        }
    }

    private func tagRow(tag: GitCommitNode.GitRef, commit: GitCommitNode?, isLatest: Bool) -> some View {
        Button(action: {
            if let c = commit { selectCommit(c); rightTab = .detail }
        }) {
            HStack(spacing: 8) {
                // Tag icon
                ZStack {
                    RoundedRectangle(cornerRadius: 4).fill(Theme.yellow.opacity(isLatest ? 0.15 : 0.06))
                        .frame(width: 24, height: 24)
                    Image(systemName: "tag.fill").font(.system(size: 10))
                        .foregroundColor(isLatest ? Theme.yellow : Theme.yellow.opacity(0.6))
                }

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text(tag.name)
                            .font(Theme.mono(10, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        if isLatest {
                            Text("latest")
                                .font(Theme.mono(6, weight: .bold))
                                .foregroundColor(Theme.green)
                                .padding(.horizontal, 4).padding(.vertical, 1)
                                .background(Capsule().fill(Theme.green.opacity(0.12)))
                        }
                    }
                    if let c = commit {
                        Text(c.message)
                            .font(Theme.mono(8))
                            .foregroundColor(Theme.textDim)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if let c = commit {
                    Text(Self.relativeDate(c.date))
                        .font(Theme.mono(7))
                        .foregroundColor(Theme.textDim)
                }
            }
            .padding(.vertical, 5).padding(.horizontal, 8)
            .background(RoundedRectangle(cornerRadius: 6).fill(isLatest ? Theme.yellow.opacity(0.03) : .clear))
        }.buttonStyle(.plain)
    }

    // ═══════════════════════════════════════════════════════
    // MARK: - Shared Components
    // ═══════════════════════════════════════════════════════

    private func sectionHeader(_ title: String, count: Int, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: Theme.iconSize(9))).foregroundColor(color)
            Text(title).font(Theme.mono(9, weight: .bold)).foregroundColor(color)
            Text("\(count)").font(Theme.mono(8, weight: .bold)).foregroundColor(color.opacity(0.6))
                .padding(.horizontal, 5).padding(.vertical, 1)
                .background(Capsule().fill(color.opacity(0.08)))
            Spacer()
        }
    }

    private func fileSection(_ title: String, files: [GitFileChange], color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader(title, count: files.count, icon: icon, color: color)
            let grouped = Dictionary(grouping: files) { ($0.path as NSString).deletingLastPathComponent }
            ForEach(grouped.keys.sorted(), id: \.self) { dir in
                if !dir.isEmpty {
                    Text(dir).font(Theme.mono(7, weight: .medium)).foregroundColor(Theme.textDim).padding(.top, 2)
                }
                ForEach(grouped[dir] ?? []) { f in fileChangeRow(f) }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface))
    }

    private func fileChangeRow(_ file: GitFileChange) -> some View {
        HStack(spacing: 6) {
            Image(systemName: file.status.icon)
                .font(.system(size: 9)).foregroundColor(file.status.color).frame(width: 14)
            Text(file.fileName)
                .font(Theme.mono(9, weight: .medium)).foregroundColor(Theme.textPrimary).lineLimit(1)
            Spacer()
            Text(file.status.rawValue)
                .font(Theme.mono(8, weight: .bold)).foregroundColor(file.status.color).frame(width: 16)
        }
        .padding(.vertical, 3).padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 4).fill(file.status.color.opacity(0.04)))
    }

    private var stashSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("스태시", count: git.stashes.count, icon: "tray.full.fill", color: Theme.cyan)
            ForEach(git.stashes) { s in
                HStack(spacing: 6) {
                    Text("stash@{\(s.id)}").font(Theme.mono(8, weight: .medium)).foregroundColor(Theme.cyan)
                    Text(s.message).font(Theme.mono(8)).foregroundColor(Theme.textSecondary).lineLimit(1)
                    Spacer()
                }
                .padding(.vertical, 3).padding(.horizontal, 8)
                .background(RoundedRectangle(cornerRadius: 4).fill(Theme.bgSurface))
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface.opacity(0.5)))
    }

    private var quickActionGrid: some View {
        let actions: [(String, String, GitAction, Color)] = [
            ("커밋", "checkmark.circle.fill", .commit, Theme.green),
            ("푸시", "arrow.up.circle.fill", .push, Theme.accent),
            ("풀", "arrow.down.circle.fill", .pull, Theme.cyan),
            ("브랜치", "arrow.triangle.branch", .branch, Theme.purple),
            ("스태시", "tray.and.arrow.down.fill", .stash, Theme.yellow),
            ("병합", "arrow.triangle.merge", .merge, Theme.orange),
        ]
        return VStack(alignment: .leading, spacing: 6) {
            sectionHeader("빠른 명령", count: actions.count, icon: "bolt.fill", color: Theme.textSecondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 6)], spacing: 6) {
                ForEach(actions, id: \.0) { (label, icon, action, color) in
                    Button(action: {
                        actionType = action; actionInput = ""
                        if action == .push || action == .pull { executeGitAction(action, input: "") }
                        else { showActionSheet = true }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: icon).font(.system(size: Theme.iconSize(9)))
                            Text(label).font(Theme.mono(8, weight: .medium))
                        }
                        .foregroundColor(color).frame(maxWidth: .infinity).padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 6).fill(color.opacity(0.06))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.12), lineWidth: 0.5)))
                    }.buttonStyle(.plain)
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface))
    }

    // ═══════════════════════════════════════════════════════
    // MARK: - Action Sheet
    // ═══════════════════════════════════════════════════════

    private var actionSheet: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: actionIcon(actionType)).font(.system(size: 16)).foregroundColor(Theme.accent)
                Text("Git \(actionType.rawValue)").font(Theme.mono(14, weight: .bold)).foregroundColor(Theme.textPrimary)
                Spacer()
            }

            Group {
                switch actionType {
                case .commit:
                    VStack(alignment: .leading, spacing: 6) {
                        Text("커밋 메시지").font(Theme.mono(9, weight: .medium)).foregroundColor(Theme.textDim)
                        TextEditor(text: $actionInput).font(Theme.monoNormal).frame(height: 80).padding(4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Theme.bgSurface))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
                    }
                case .branch:
                    VStack(alignment: .leading, spacing: 6) {
                        Text("브랜치 이름").font(Theme.mono(9, weight: .medium)).foregroundColor(Theme.textDim)
                        TextField("feature/...", text: $actionInput).font(Theme.monoNormal).textFieldStyle(.plain).padding(8)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Theme.bgSurface))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
                    }
                case .stash:
                    VStack(alignment: .leading, spacing: 6) {
                        Text("스태시 메시지 (선택)").font(Theme.mono(9, weight: .medium)).foregroundColor(Theme.textDim)
                        TextField("작업 중인 변경사항...", text: $actionInput).font(Theme.monoNormal).textFieldStyle(.plain).padding(8)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Theme.bgSurface))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
                    }
                case .merge, .checkout:
                    VStack(alignment: .leading, spacing: 6) {
                        Text(actionType == .merge ? "병합할 브랜치" : "체크아웃할 브랜치")
                            .font(Theme.mono(9, weight: .medium)).foregroundColor(Theme.textDim)
                        ScrollView {
                            VStack(spacing: 2) {
                                ForEach(git.branches.filter { b in actionType == .merge ? (!b.isCurrent && !b.isRemote) : !b.isCurrent }) { br in
                                    Button(action: { actionInput = br.name }) {
                                        HStack {
                                            Image(systemName: br.isRemote ? "cloud" : "arrow.triangle.branch").font(.system(size: 9))
                                            Text(br.name).font(Theme.mono(10))
                                            Spacer()
                                            if actionInput == br.name {
                                                Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(Theme.green)
                                            }
                                        }
                                        .foregroundColor(actionInput == br.name ? Theme.accent : Theme.textSecondary)
                                        .padding(.horizontal, 8).padding(.vertical, 5)
                                        .background(RoundedRectangle(cornerRadius: 4).fill(actionInput == br.name ? Theme.accent.opacity(0.1) : .clear))
                                    }.buttonStyle(.plain)
                                }
                            }
                        }.frame(maxHeight: 150)
                    }
                default: EmptyView()
                }
            }

            HStack {
                Button("취소") { showActionSheet = false }
                    .font(Theme.mono(10, weight: .medium)).foregroundColor(Theme.textDim)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Theme.bgSurface))
                    .buttonStyle(.plain)
                Spacer()
                Button(action: { executeGitAction(actionType, input: actionInput); showActionSheet = false }) {
                    HStack(spacing: 4) {
                        Image(systemName: "paperplane.fill").font(.system(size: 9))
                        Text("Claude에게 요청").font(Theme.mono(10, weight: .bold))
                    }
                    .foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Theme.accent))
                }
                .buttonStyle(.plain)
                .disabled(needsInput && actionInput.isEmpty)
                .opacity(needsInput && actionInput.isEmpty ? 0.5 : 1)
            }
        }
        .padding(20).frame(width: 420).background(Theme.bgCard)
    }

    private var needsInput: Bool {
        switch actionType {
        case .commit, .branch, .merge, .checkout: return true
        default: return false
        }
    }

    private func actionIcon(_ action: GitAction) -> String {
        switch action {
        case .commit: return "checkmark.circle"
        case .push: return "arrow.up.circle"
        case .pull: return "arrow.down.circle"
        case .branch: return "arrow.triangle.branch"
        case .stash: return "tray.and.arrow.down"
        case .merge: return "arrow.triangle.merge"
        case .checkout: return "arrow.uturn.right"
        }
    }

    // ═══════════════════════════════════════════════════════
    // MARK: - Actions & Helpers
    // ═══════════════════════════════════════════════════════

    private func executeGitAction(_ action: GitAction, input: String) {
        guard let tab = activeTab else { return }
        let prompt: String
        switch action {
        case .commit: prompt = "현재 변경사항을 커밋해주세요. 커밋 메시지: \"\(input)\""
        case .push: prompt = "현재 브랜치를 리모트에 푸시해주세요."
        case .pull: prompt = "리모트에서 최신 변경사항을 풀해주세요."
        case .branch: prompt = "새 브랜치 '\(input)'를 생성하고 체크아웃해주세요."
        case .stash: prompt = input.isEmpty ? "현재 변경사항을 스태시해주세요." : "현재 변경사항을 스태시해주세요. 메시지: \"\(input)\""
        case .merge: prompt = "브랜치 '\(input)'를 현재 브랜치에 병합해주세요."
        case .checkout: prompt = "브랜치 '\(input)'로 체크아웃해주세요."
        }
        tab.sendPrompt(prompt)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak git] in git?.refreshAll() }
    }

    private func selectCommit(_ commit: GitCommitNode) {
        selectedCommitId = commit.id
        git.fetchCommitFiles(hash: commit.id)
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text).font(Theme.mono(7, weight: .bold)).foregroundColor(color)
            .padding(.horizontal, 5).padding(.vertical, 1)
            .background(Capsule().fill(color.opacity(0.12)))
    }

    private func metaRow(_ label: String, _ value: String, mono: Bool = false, copyValue: String? = nil) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label).font(Theme.mono(8, weight: .bold)).foregroundColor(Theme.textDim)
                .frame(width: 52, alignment: .trailing)
            Text(value).font(mono ? Theme.mono(9, weight: .medium) : Theme.mono(9))
                .foregroundColor(Theme.textPrimary).textSelection(.enabled)
            if let cv = copyValue {
                Button(action: { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(cv, forType: .string) }) {
                    Image(systemName: "doc.on.doc").font(.system(size: 8)).foregroundColor(Theme.textDim)
                }.buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private func emptyState(_ msg: String, icon: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 32)).foregroundColor(Theme.textDim.opacity(0.3))
            Text(msg).font(Theme.mono(11)).foregroundColor(Theme.textDim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private static let fullDateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy.MM.dd HH:mm:ss"; return f
    }()

    static func relativeDate(_ date: Date) -> String {
        let s = Int(Date().timeIntervalSince(date))
        if s < 60 { return "방금" }
        if s < 3600 { return "\(s / 60)분 전" }
        if s < 86400 { return "\(s / 3600)시간 전" }
        if s < 604800 { return "\(s / 86400)일 전" }
        return fullDateFormatter.string(from: date)
    }

    static func formatDate(_ date: Date) -> String { fullDateFormatter.string(from: date) }
}
