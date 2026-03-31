import SwiftUI
import DesignSystem

extension GitPanelView {
    // ═══════════════════════════════════════════════════════
    // MARK: - Conflict Banner
    // ═══════════════════════════════════════════════════════

    var conflictBanner: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showConflictList.toggle() } }) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.red)
                    Text(String(format: NSLocalizedString("git.conflict.count", comment: ""), git.conflictFiles.count))
                        .font(Theme.chrome(10, weight: .bold))
                        .foregroundColor(Theme.red)
                    Spacer()
                    Image(systemName: showConflictList ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Theme.red.opacity(0.6))
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Theme.red.opacity(0.08))
            }
            .buttonStyle(.plain)

            if showConflictList {
                VStack(spacing: 2) {
                    ForEach(git.conflictFiles) { file in
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 9))
                                .foregroundColor(Theme.red)
                            Text(file.fileName)
                                .font(Theme.mono(9, weight: .medium))
                                .foregroundColor(Theme.textPrimary)
                                .lineLimit(1)
                            Spacer()
                            Button("Ours") {
                                resolveConflict(file.path, strategy: "ours")
                            }
                            .font(Theme.mono(7, weight: .bold))
                            .foregroundColor(Theme.green)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 4).fill(Theme.green.opacity(0.1)))
                            .buttonStyle(.plain)

                            Button("Theirs") {
                                resolveConflict(file.path, strategy: "theirs")
                            }
                            .font(Theme.mono(7, weight: .bold))
                            .foregroundStyle(Theme.accentBackground)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 4).fill(Theme.accent.opacity(0.1)))
                            .buttonStyle(.plain)

                            Button(NSLocalizedString("git.conflict.manual", comment: "")) {
                                if let tab = activeTab {
                                    tab.sendPrompt(String(format: NSLocalizedString("git.conflict.manual.prompt", comment: ""), file.path))
                                }
                            }
                            .font(Theme.mono(7, weight: .bold))
                            .foregroundColor(Theme.yellow)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 4).fill(Theme.yellow.opacity(0.1)))
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 4)
                    }
                }
                .padding(.bottom, 6)
                .background(Theme.red.opacity(0.03))
            }
        }
    }

    func resolveConflict(_ filePath: String, strategy: String) {
        guard let tab = activeTab else { return }
        tab.sendPrompt(String(format: NSLocalizedString("git.conflict.resolve.prompt", comment: ""), filePath, strategy))
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak git] in git?.refreshAll() }
    }

    // ═══════════════════════════════════════════════════════
    // MARK: - Left Sidebar
    // ═══════════════════════════════════════════════════════

    var leftSidebar: some View {
        VStack(spacing: 0) {
            // Sidebar header
            HStack(spacing: 6) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Theme.textDim)
                Text(NSLocalizedString("git.explore", comment: ""))
                    .font(Theme.chrome(9, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(Theme.bgCard)
            Rectangle().fill(Theme.border).frame(height: 1)

            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: []) {
                    // Branches section
                    sidebarSection(
                        title: NSLocalizedString("git.branch", comment: ""),
                        icon: "arrow.triangle.branch",
                        color: Theme.accent,
                        count: localBranches.count,
                        isExpanded: $sidebarBranchesExpanded
                    ) {
                        ForEach(localBranches) { br in
                            sidebarBranchItem(br)
                        }
                    }

                    sidebarDivider

                    // Tags section
                    sidebarSection(
                        title: NSLocalizedString("git.tags", comment: ""),
                        icon: "tag.fill",
                        color: Theme.yellow,
                        count: allTags.count,
                        isExpanded: $sidebarTagsExpanded
                    ) {
                        ForEach(allTags, id: \.name) { tag in
                            sidebarTagItem(tag)
                        }
                    }

                    sidebarDivider

                    // Stashes section
                    sidebarSection(
                        title: NSLocalizedString("git.stash", comment: ""),
                        icon: "tray.full.fill",
                        color: Theme.cyan,
                        count: git.stashes.count,
                        isExpanded: $sidebarStashesExpanded
                    ) {
                        ForEach(git.stashes) { stash in
                            sidebarStashItem(stash)
                        }
                    }

                    sidebarDivider

                    // Remotes section
                    sidebarSection(
                        title: NSLocalizedString("git.remotes", comment: ""),
                        icon: "cloud.fill",
                        color: Theme.purple,
                        count: remoteNames.count,
                        isExpanded: $sidebarRemotesExpanded
                    ) {
                        ForEach(remoteNames, id: \.self) { remote in
                            sidebarRemoteItem(remote)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .background(Theme.bgCard.opacity(0.5))
    }

    var sidebarDivider: some View {
        Rectangle().fill(Theme.border.opacity(0.5)).frame(height: 0.5)
            .padding(.horizontal, 8)
    }

    func sidebarSection<Content: View>(
        title: String,
        icon: String,
        color: Color,
        count: Int,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation(.easeInOut(duration: 0.15)) { isExpanded.wrappedValue.toggle() } }) {
                HStack(spacing: 6) {
                    Image(systemName: isExpanded.wrappedValue ? "chevron.down" : "chevron.right")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(Theme.textDim)
                        .frame(width: 10)
                    Image(systemName: icon)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(color)
                    Text(title)
                        .font(Theme.chrome(9, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    Text("\(count)")
                        .font(Theme.mono(7, weight: .bold))
                        .foregroundColor(color.opacity(0.7))
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(Capsule().fill(color.opacity(0.08)))
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded.wrappedValue {
                VStack(spacing: 1) {
                    content()
                }
                .padding(.leading, 8).padding(.trailing, 4).padding(.bottom, 4)
            }
        }
    }

    func sidebarBranchItem(_ br: GitBranchInfo) -> some View {
        Button(action: {
            if !br.isCurrent {
                actionType = .checkout; actionInput = br.name; showActionSheet = true
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: br.isCurrent ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(br.isCurrent ? Theme.green : Theme.textDim.opacity(0.4))
                Text(br.name)
                    .font(Theme.mono(8, weight: br.isCurrent ? .bold : .regular))
                    .foregroundColor(br.isCurrent ? Theme.textPrimary : Theme.textSecondary)
                    .lineLimit(1)
                Spacer()
                if br.ahead > 0 {
                    Text("↑\(br.ahead)").font(Theme.mono(6, weight: .bold)).foregroundColor(Theme.green)
                }
                if br.behind > 0 {
                    Text("↓\(br.behind)").font(Theme.mono(6, weight: .bold)).foregroundColor(Theme.orange)
                }
            }
            .padding(.vertical, 3).padding(.horizontal, 6)
            .background(RoundedRectangle(cornerRadius: 4).fill(br.isCurrent ? Theme.green.opacity(0.06) : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            if !br.isCurrent {
                Button(NSLocalizedString("git.checkout", comment: "")) {
                    actionType = .checkout; actionInput = br.name; showActionSheet = true
                }
                Divider()
                Button(NSLocalizedString("git.branch.delete", comment: ""), role: .destructive) {
                    branchToDelete = br.name
                    showDeleteBranchAlert = true
                }
            }
        }
    }

    func sidebarTagItem(_ tag: GitCommitNode.GitRef) -> some View {
        Button(action: {
            if let commit = git.commits.first(where: { $0.refs.contains(where: { $0.name == tag.name && $0.type == .tag }) }) {
                selectCommit(commit)
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 7))
                    .foregroundColor(Theme.yellow.opacity(0.7))
                Text(tag.name)
                    .font(Theme.mono(8))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.vertical, 3).padding(.horizontal, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(NSLocalizedString("git.tag.delete", comment: ""), role: .destructive) {
                git.deleteTag(name: tag.name)
            }
        }
    }

    func sidebarStashItem(_ stash: GitStashEntry) -> some View {
        Button(action: {
            // Preview stash — select it
            selectedCommitId = nil
        }) {
            HStack(spacing: 6) {
                Image(systemName: "tray.fill")
                    .font(.system(size: 7))
                    .foregroundColor(Theme.cyan.opacity(0.7))
                VStack(alignment: .leading, spacing: 1) {
                    Text("stash@{\(stash.id)}")
                        .font(Theme.mono(7, weight: .medium))
                        .foregroundColor(Theme.cyan)
                    Text(stash.message)
                        .font(Theme.mono(7))
                        .foregroundColor(Theme.textDim)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.vertical, 3).padding(.horizontal, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(NSLocalizedString("git.stash.apply", comment: "")) { git.stashApply(index: stash.id) }
            Button(NSLocalizedString("git.stash.drop", comment: ""), role: .destructive) { git.stashDrop(index: stash.id) }
        }
    }

    func sidebarRemoteItem(_ remote: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "cloud.fill")
                .font(.system(size: 7))
                .foregroundColor(Theme.purple.opacity(0.7))
            Text(remote)
                .font(Theme.mono(8, weight: .medium))
                .foregroundColor(Theme.textSecondary)
            Spacer()
            let count = remoteBranches.filter { $0.name.hasPrefix("\(remote)/") }.count
            Text("\(count)")
                .font(Theme.mono(6, weight: .bold))
                .foregroundColor(Theme.textDim)
        }
        .padding(.vertical, 3).padding(.horizontal, 6)
    }
}
