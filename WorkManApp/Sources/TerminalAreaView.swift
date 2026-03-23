import SwiftUI

// ═══════════════════════════════════════════════════════
// MARK: - Terminal Area
// ═══════════════════════════════════════════════════════

struct TerminalAreaView: View {
    @EnvironmentObject var manager: SessionManager
    @State private var viewMode: ViewMode = .grid
    enum ViewMode { case grid, single }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            switch viewMode {
            case .grid: GridPanelView()
            case .single:
                if let tab = manager.activeTab { EventStreamView(tab: tab, compact: false) }
                else { EmptySessionView() }
            }
        }
        .sheet(isPresented: $manager.showNewTabSheet) { NewTabSheet() }
    }

    private var topBar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 2) {
                modeBtn("square.grid.2x2", .grid); modeBtn("rectangle", .single)
            }.padding(.horizontal, 8)
            Rectangle().fill(Theme.border).frame(width: 1, height: 18)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 3) {
                    if viewMode == .single { ForEach(manager.tabs) { t in singleTabBtn(t) } }
                }.padding(.horizontal, 6)
            }
            Spacer(minLength: 0)
            Button(action: { manager.showNewTabSheet = true }) {
                Image(systemName: "plus").font(.system(size: 10, weight: .medium)).foregroundColor(Theme.textDim).frame(width: 28, height: 28)
            }.buttonStyle(.plain).padding(.trailing, 6)
        }
        .frame(height: 34).background(Theme.bgCard)
        .overlay(Rectangle().fill(Theme.border).frame(height: 1), alignment: .bottom)
    }

    private func modeBtn(_ icon: String, _ mode: ViewMode) -> some View {
        let label = mode == .grid ? "Grid" : "Single"
        let selected = viewMode == mode
        return Button(action: { withAnimation(.easeInOut(duration: 0.2)) { viewMode = mode } }) {
            HStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 9))
                Text(label).font(Theme.mono(8, weight: selected ? .bold : .regular))
            }
            .foregroundColor(selected ? Theme.accent : Theme.textDim).padding(.horizontal, 6).padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 4).fill(selected ? Theme.accent.opacity(0.12) : .clear))
        }.buttonStyle(.plain)
    }
    private func singleTabBtn(_ t: TerminalTab) -> some View {
        let a = manager.activeTabId == t.id
        return Button(action: { manager.selectTab(t.id) }) {
            HStack(spacing: 4) {
                Circle().fill(t.isProcessing ? Theme.yellow : t.workerColor).frame(width: 5, height: 5)
                Text(t.projectName).font(Theme.monoSmall).foregroundColor(a ? Theme.textPrimary : Theme.textSecondary).lineLimit(1)
                if manager.tabs.filter({ $0.projectPath == t.projectPath }).count > 1 {
                    Text(t.workerName).font(Theme.monoTiny).foregroundColor(t.workerColor)
                }
            }.padding(.horizontal, 8).padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 5).fill(a ? Theme.bgSelected : .clear))
        }.buttonStyle(.plain)
    }
}

// ═══════════════════════════════════════════════════════
// MARK: - Event Stream View
// ═══════════════════════════════════════════════════════

struct EventStreamView: View {
    @ObservedObject var tab: TerminalTab
    @ObservedObject private var settings = AppSettings.shared
    let compact: Bool
    @State private var inputText = ""
    @FocusState private var isFocused: Bool
    @State private var autoScroll = true
    @State private var lastBlockCount = 0
    @State private var blockFilter = BlockFilter()
    @State private var showFilterBar = false
    @State private var showFilePanel = false
    @State private var elapsedSeconds: Int = 0
    let elapsedTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // [Feature 2] 작업 상태 바
            if !compact { statusBar }

            // [Feature 6] 필터 바
            if showFilterBar && !compact { filterBar }

            // Main content
            HStack(spacing: 0) {
                // Event stream
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(filteredBlocks) { block in
                                EventBlockView(block: block, compact: compact)
                                    .id(block.id)
                            }

                            if tab.isProcessing {
                                ProcessingIndicator(activity: tab.claudeActivity, workerColor: tab.workerColor, workerName: tab.workerName)
                                    .id("processing")
                            }

                            Color.clear.frame(height: 1).id("streamEnd")
                        }
                        .padding(.horizontal, compact ? 8 : 14)
                        .padding(.vertical, 8)
                    }
                    .background(Theme.bgTerminal)
                    .onChange(of: tab.blocks.count) { newCount in
                        if autoScroll && newCount != lastBlockCount {
                            lastBlockCount = newCount
                            scrollToEnd(proxy)
                        }
                    }
                    .onChange(of: tab.scrollTrigger) { _ in
                        if autoScroll { scrollToEnd(proxy) }
                    }
                    .onChange(of: tab.isProcessing) { processing in
                        // 처리 완료 시 최종 결과로 스크롤
                        if !processing && autoScroll {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { scrollToEnd(proxy) }
                        }
                    }
                    .onChange(of: tab.claudeActivity) { _ in
                        // 활동 상태 변경될 때마다 스크롤 (tool 전환 등)
                        if autoScroll { scrollToEnd(proxy) }
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { scrollToEnd(proxy) }
                    }
                }

                // [Feature 4] 파일 변경 패널
                if showFilePanel && !compact {
                    Rectangle().fill(Theme.border).frame(width: 1)
                    fileChangePanel
                }
            }

            if !compact { fullInputBar } else { compactInputBar }
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { isFocused = true } }
        .onReceive(elapsedTimer) { _ in
            if tab.isProcessing || tab.claudeActivity != .idle {
                elapsedSeconds = Int(Date().timeIntervalSince(tab.startTime))
            }
        }
        // [Feature 5] 승인 모달
        .sheet(item: $tab.pendingApproval) { approval in
            ApprovalSheet(approval: approval)
        }
    }

    // ═══════════════════════════════════════════
    // MARK: - [Feature 2] Status Bar
    // ═══════════════════════════════════════════

    private var statusBar: some View {
        HStack(spacing: 8) {
            // Worker + Activity
            HStack(spacing: 4) {
                Circle().fill(tab.workerColor).frame(width: 6, height: 6)
                Text(tab.workerName).font(Theme.mono(9, weight: .semibold)).foregroundColor(tab.workerColor)
                Text(activityLabel).font(Theme.mono(9)).foregroundColor(activityLabelColor)
            }

            Rectangle().fill(Theme.border).frame(width: 1, height: 12)

            // Elapsed time
            HStack(spacing: 3) {
                Image(systemName: "clock").font(Theme.mono(8)).foregroundColor(Theme.textDim)
                Text(formatElapsed(elapsedSeconds)).font(Theme.mono(9)).foregroundColor(Theme.textSecondary)
            }

            // File count
            if !tab.fileChanges.isEmpty {
                Rectangle().fill(Theme.border).frame(width: 1, height: 12)
                HStack(spacing: 3) {
                    Image(systemName: "doc.fill").font(Theme.mono(8)).foregroundColor(Theme.green)
                    Text("\(Set(tab.fileChanges.map(\.fileName)).count) files").font(Theme.mono(9, weight: .bold)).foregroundColor(Theme.green)
                }
            }

            // Error count
            if tab.errorCount > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "exclamationmark.triangle.fill").font(Theme.mono(7)).foregroundColor(Theme.red)
                    Text("\(tab.errorCount) errors").font(Theme.mono(9, weight: .bold)).foregroundColor(Theme.red)
                }
            }

            // Commands
            if tab.commandCount > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "terminal").font(Theme.mono(7)).foregroundColor(Theme.textDim)
                    Text("\(tab.commandCount) cmds").font(Theme.mono(9)).foregroundColor(Theme.textSecondary)
                }
            }

            Spacer()

            // Toggle buttons
            Button(action: { withAnimation(.easeInOut(duration: 0.15)) { showFilterBar.toggle() } }) {
                HStack(spacing: 3) {
                    Image(systemName: "line.3.horizontal.decrease.circle\(showFilterBar ? ".fill" : "")")
                        .font(Theme.mono(8))
                    Text("필터").font(Theme.mono(8, weight: showFilterBar ? .bold : .regular))
                }
                .foregroundColor(showFilterBar || blockFilter.isActive ? Theme.accent : Theme.textDim)
                .padding(.horizontal, 5).padding(.vertical, 2)
                .background(showFilterBar ? Theme.accent.opacity(0.08) : .clear).cornerRadius(4)
            }.buttonStyle(.plain).help("로그 필터")

            Button(action: { withAnimation(.easeInOut(duration: 0.15)) { showFilePanel.toggle() } }) {
                HStack(spacing: 3) {
                    Image(systemName: "doc.text.magnifyingglass").font(Theme.mono(8))
                    Text("파일").font(Theme.mono(8, weight: showFilePanel ? .bold : .regular))
                }
                .foregroundColor(showFilePanel ? Theme.accent : Theme.textDim)
                .padding(.horizontal, 5).padding(.vertical, 2)
                .background(showFilePanel ? Theme.accent.opacity(0.08) : .clear).cornerRadius(4)
            }.buttonStyle(.plain).help("파일 변경")
        }
        .padding(.horizontal, 12).padding(.vertical, 5)
        .background(Theme.bgSurface.opacity(0.5))
        .overlay(Rectangle().fill(Theme.border).frame(height: 1), alignment: .bottom)
    }

    private var activityLabel: String {
        switch tab.claudeActivity {
        case .idle: return "대기"; case .thinking: return "생각 중"; case .reading: return "읽는 중"
        case .writing: return "작성 중"; case .searching: return "검색 중"; case .running: return "실행 중"
        case .done: return "완료"; case .error: return "에러"
        }
    }

    private var activityLabelColor: Color {
        switch tab.claudeActivity {
        case .thinking: return Theme.purple; case .reading: return Theme.accent; case .writing: return Theme.green
        case .searching: return Theme.cyan; case .running: return Theme.yellow; case .done: return Theme.green
        case .error: return Theme.red; case .idle: return Theme.textDim
        }
    }

    private func formatElapsed(_ secs: Int) -> String {
        if secs < 60 { return "\(secs)s" }
        if secs < 3600 { return "\(secs / 60)m \(secs % 60)s" }
        return "\(secs / 3600)h \((secs % 3600) / 60)m"
    }

    // ═══════════════════════════════════════════
    // MARK: - [Feature 6] Filter Bar
    // ═══════════════════════════════════════════

    private var filterBar: some View {
        HStack(spacing: 4) {
            Text("Filter").font(Theme.mono(8, weight: .bold)).foregroundColor(Theme.textDim)
            ForEach(["Bash", "Read", "Write", "Edit", "Grep", "Glob"], id: \.self) { tool in
                filterChip(tool, color: toolColor(tool))
            }
            Rectangle().fill(Theme.border).frame(width: 1, height: 12)
            Button(action: { blockFilter.onlyErrors.toggle() }) {
                Text("Errors").font(Theme.mono(8, weight: blockFilter.onlyErrors ? .bold : .regular))
                    .foregroundColor(blockFilter.onlyErrors ? Theme.red : Theme.textDim)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(blockFilter.onlyErrors ? Theme.red.opacity(0.1) : .clear).cornerRadius(3)
            }.buttonStyle(.plain)
            Spacer()
            if blockFilter.isActive {
                Button(action: { blockFilter = BlockFilter() }) {
                    Text("Clear").font(Theme.mono(8)).foregroundColor(Theme.accent)
                }.buttonStyle(.plain)
            }
            // Search
            HStack(spacing: 3) {
                Image(systemName: "magnifyingglass").font(Theme.mono(8)).foregroundColor(Theme.textDim)
                TextField("검색...", text: $blockFilter.searchText)
                    .textFieldStyle(.plain).font(Theme.mono(9)).frame(width: 80)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 4)
        .background(Theme.bgSurface.opacity(0.3))
        .overlay(Rectangle().fill(Theme.border).frame(height: 1), alignment: .bottom)
    }

    private func filterChip(_ tool: String, color: Color) -> some View {
        let active = blockFilter.toolTypes.contains(tool)
        return Button(action: {
            if active { blockFilter.toolTypes.remove(tool) }
            else { blockFilter.toolTypes.insert(tool) }
        }) {
            Text(tool).font(Theme.mono(8, weight: active ? .bold : .regular))
                .foregroundColor(active ? color : Theme.textDim)
                .padding(.horizontal, 5).padding(.vertical, 2)
                .background(active ? color.opacity(0.1) : .clear).cornerRadius(3)
        }.buttonStyle(.plain)
    }

    private func toolColor(_ name: String) -> Color {
        switch name {
        case "Bash": return Theme.yellow; case "Read": return Theme.accent
        case "Write", "Edit": return Theme.green; case "Grep", "Glob": return Theme.cyan
        default: return Theme.textSecondary
        }
    }

    // ═══════════════════════════════════════════
    // MARK: - [Feature 4] File Change Panel
    // ═══════════════════════════════════════════

    private var fileChangePanel: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "doc.text").font(Theme.mono(9)).foregroundColor(Theme.accent)
                Text("FILES").font(Theme.pixel).foregroundColor(Theme.textDim).tracking(1.5)
                Spacer()
                Text("\(Set(tab.fileChanges.map(\.fileName)).count)")
                    .font(Theme.mono(9, weight: .bold)).foregroundColor(Theme.accent)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Theme.bgSurface.opacity(0.5))

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    // Group by unique file
                    let grouped = Dictionary(grouping: tab.fileChanges, by: \.path)
                    ForEach(Array(grouped.keys.sorted()), id: \.self) { path in
                        if let records = grouped[path], let latest = records.last {
                        HStack(spacing: 6) {
                            Image(systemName: latest.action == "Write" ? "doc.badge.plus" : "pencil.line")
                                .font(Theme.mono(8)).foregroundColor(Theme.green)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(latest.fileName).font(Theme.mono(9, weight: .medium)).foregroundColor(Theme.textPrimary).lineLimit(1)
                                Text("\(latest.action) x\(records.count)")
                                    .font(Theme.mono(7)).foregroundColor(Theme.textDim)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        } // if let records
                    }

                    if tab.fileChanges.isEmpty {
                        Text("변경된 파일 없음").font(Theme.monoSmall).foregroundColor(Theme.textDim)
                            .frame(maxWidth: .infinity).padding(.vertical, 20)
                    }
                }
            }
        }
        .frame(width: 180)
        .background(Theme.bgCard)
    }

    // ═══════════════════════════════════════════
    // MARK: - Filtered Blocks (기존 확장)
    // ═══════════════════════════════════════════

    private func scrollToEnd(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            proxy.scrollTo("streamEnd", anchor: .bottom)
        }
        // 추가 보장: 레이아웃이 완료된 후 한 번 더
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            proxy.scrollTo("streamEnd", anchor: .bottom)
        }
    }

    private var filteredBlocks: [StreamBlock] {
        var blocks: [StreamBlock]
        switch tab.outputMode {
        case .full: blocks = tab.blocks
        case .realtime: blocks = tab.blocks.filter { if case .sessionStart = $0.blockType { return false }; return true }
        case .resultOnly:
            blocks = tab.blocks.filter {
                switch $0.blockType {
                case .userPrompt, .thought, .completion, .error: return true
                default: return false
                }
            }
        }
        // 추가 필터 적용
        if blockFilter.isActive {
            blocks = blocks.filter { blockFilter.matches($0) }
        }
        return blocks
    }

    // MARK: - Input Bars

    private var fullInputBar: some View {
        VStack(spacing: 0) {
            // Settings
            HStack(spacing: 0) {
                // Model
                settingGroup("Model") {
                    ForEach(ClaudeModel.allCases) { m in
                        settingChip(m.displayName, isSelected: tab.selectedModel == m, color: modelColor(m)) { tab.selectedModel = m }
                    }
                }

                settingSep

                // Effort
                settingGroup("Effort") {
                    ForEach(EffortLevel.allCases) { l in
                        let name = l.rawValue.prefix(1).uppercased() + l.rawValue.dropFirst()
                        settingChip(name, isSelected: tab.effortLevel == l, color: Theme.accent) { tab.effortLevel = l }
                    }
                }

                settingSep

                // Output
                settingGroup("Output") {
                    ForEach(OutputMode.allCases) { m in
                        settingChip(m.rawValue, isSelected: tab.outputMode == m, color: Theme.cyan) { tab.outputMode = m }
                    }
                }

                settingSep

                // Permission
                settingGroup("권한") {
                    ForEach(PermissionMode.allCases) { m in
                        settingChip(m.displayName, isSelected: tab.permissionMode == m, color: permissionColor(m)) { tab.permissionMode = m }
                            .help(m.desc)
                    }
                }

                Spacer(minLength: 4)

                if tab.totalCost > 0 {
                    Text(String(format: "$%.4f", tab.totalCost))
                        .font(Theme.mono(9, weight: .semibold)).foregroundColor(Theme.yellow)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(Theme.yellow.opacity(0.06)).cornerRadius(4)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 3)
            .background(Theme.bgSurface.opacity(0.6))

            // 설정 ↔ 입력 구분선
            Rectangle().fill(Theme.border).frame(height: 1)

            // Input
            HStack(spacing: 8) {
                HStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 1).fill(tab.workerColor).frame(width: 3, height: 16)
                    Text(tab.projectName).font(Theme.monoSmall).foregroundColor(Theme.textDim)
                    Text(">").font(Theme.mono(12, weight: .semibold)).foregroundColor(Theme.accent)
                }
                TextField(tab.isProcessing ? "실행 중..." : "명령을 입력하세요", text: $inputText)
                    .textFieldStyle(.plain).font(Theme.monoNormal)
                    .foregroundColor(Theme.textPrimary).focused($isFocused)
                    .disabled(tab.isProcessing).onSubmit { submit() }
                if tab.isProcessing {
                    Button(action: { tab.cancelProcessing() }) {
                        Label("Stop", systemImage: "stop.fill").font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(Theme.red).padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Theme.red.opacity(0.1)).cornerRadius(5)
                    }.buttonStyle(.plain)
                } else {
                    Button(action: { submit() }) {
                        Image(systemName: "arrow.up.circle.fill").font(.system(size: 20))
                            .foregroundColor(inputText.isEmpty ? Theme.textDim : Theme.accent)
                    }.buttonStyle(.plain).disabled(inputText.isEmpty)
                }
            }.padding(.horizontal, 14).padding(.vertical, 8)
        }
        .background(Theme.bgInput)
        .overlay(
            VStack(spacing: 0) {
                Rectangle().fill(Theme.textDim.opacity(0.3)).frame(height: 1)
                Spacer()
                Rectangle().fill(Theme.textDim.opacity(0.3)).frame(height: 1)
            }
        )
    }

    private var compactInputBar: some View {
        HStack(spacing: 4) {
            TextField("입력...", text: $inputText)
                .textFieldStyle(.plain).font(Theme.monoSmall)
                .foregroundColor(Theme.textPrimary).focused($isFocused)
                .disabled(tab.isProcessing).onSubmit { submit() }
            if tab.isProcessing {
                Button(action: { tab.cancelProcessing() }) {
                    Image(systemName: "stop.fill").font(.system(size: 7)).foregroundColor(Theme.red)
                }.buttonStyle(.plain)
            } else {
                Button(action: { submit() }) {
                    Image(systemName: "arrow.up.circle.fill").font(.system(size: 14))
                        .foregroundColor(inputText.isEmpty ? Theme.textDim : Theme.accent)
                }.buttonStyle(.plain).disabled(inputText.isEmpty)
            }
        }.padding(.horizontal, 8).padding(.vertical, 5).background(Theme.bgInput)
    }

    private func submit() {
        let p = inputText.trimmingCharacters(in: .whitespaces); guard !p.isEmpty else { return }
        inputText = ""; tab.sendPrompt(p)
        AchievementManager.shared.addXP(5); AchievementManager.shared.incrementCommand()
    }

    // MARK: - Setting Helpers

    private func settingGroup<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(Theme.mono(8, weight: .medium))
                .foregroundColor(Theme.textDim)
                .fixedSize()
            HStack(spacing: 2) {
                content()
            }
        }
        .padding(.horizontal, 6)
    }

    private var settingSep: some View {
        Rectangle().fill(Theme.textDim.opacity(0.25)).frame(width: 1, height: 18).padding(.horizontal, 4)
    }

    private func settingChip(_ label: String, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.12)) { action() } }) {
            Text(label)
                .font(Theme.mono(9, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? color : Theme.textDim)
                .fixedSize()
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? color.opacity(0.14) : .clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? color.opacity(0.3) : .clear, lineWidth: 0.5)
                )
        }.buttonStyle(.plain)
    }

    private func modelColor(_ m: ClaudeModel) -> Color {
        switch m {
        case .opus: return Theme.purple
        case .sonnet: return Theme.accent
        case .haiku: return Theme.green
        }
    }

    private func approvalColor(_ m: ApprovalMode) -> Color {
        switch m {
        case .auto: return Theme.yellow
        case .ask: return Theme.orange
        case .safe: return Theme.green
        }
    }

    private func permissionColor(_ m: PermissionMode) -> Color {
        switch m {
        case .bypassPermissions: return Theme.yellow
        case .auto: return Theme.cyan
        case .defaultMode: return Theme.orange
        case .plan: return Theme.purple
        }
    }
}

// ═══════════════════════════════════════════════════════
// MARK: - Event Block View
// ═══════════════════════════════════════════════════════

struct EventBlockView: View {
    @ObservedObject var block: StreamBlock
    @ObservedObject private var settings = AppSettings.shared
    let compact: Bool

    var body: some View {
        switch block.blockType {
        case .sessionStart:
            sessionStartBlock
        case .userPrompt:
            userPromptBlock
        case .thought:
            thoughtBlock
        case .toolUse(let name, _):
            toolUseBlock(name: name)
        case .toolOutput:
            toolOutputBlock
        case .toolError:
            toolErrorBlock
        case .toolEnd(let success):
            toolEndBlock(success: success)
        case .fileChange(_, let action):
            fileChangeBlock(action: action)
        case .status(let msg):
            statusBlock(msg)
        case .completion(let cost, let duration):
            completionBlock(cost: cost, duration: duration)
        case .error(let msg):
            errorBlock(msg)
        case .text:
            textBlock
        }
    }

    // MARK: - Block Styles

    private var sessionStartBlock: some View {
        HStack(spacing: 6) {
            Image(systemName: "play.circle.fill").font(.system(size: 10)).foregroundColor(Theme.green)
            Text(block.content).font(Theme.monoSmall).foregroundColor(Theme.textSecondary)
        }
        .padding(.vertical, 4)
    }

    private var userPromptBlock: some View {
        HStack(alignment: .top, spacing: 6) {
            Text(">").font(Theme.mono(13, weight: .bold)).foregroundColor(Theme.accent)
            Text(block.content).font(Theme.mono(compact ? 11 : 13)).foregroundColor(Theme.accent)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 6).padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 6).fill(Theme.accent.opacity(0.06)))
    }

    private var thoughtBlock: some View {
        HStack(alignment: .top, spacing: 6) {
            Circle().fill(Theme.textDim).frame(width: 4, height: 4).padding(.top, 6)
            MarkdownTextView(text: block.content, compact: compact)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }.padding(.vertical, 2)
    }

    private func toolUseBlock(name: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(toolColor(name)).frame(width: 6, height: 6)
            Text("\(name)").font(Theme.mono(compact ? 10 : 11, weight: .bold)).foregroundColor(toolColor(name))
            Text("(\(block.content))").font(Theme.mono(compact ? 10 : 11)).foregroundColor(Theme.textSecondary).lineLimit(1)
            if !block.isComplete { ProgressView().scaleEffect(0.4).frame(width: 10, height: 10) }
        }
        .padding(.vertical, 4).padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(toolColor(name).opacity(0.06)))
    }

    private var toolOutputBlock: some View {
        HStack(alignment: .top, spacing: 0) {
            Text("  | ").font(Theme.mono(11)).foregroundColor(Theme.textDim)
            Text(block.content)
                .font(Theme.mono(compact ? 10 : 11))
                .foregroundColor(Theme.textTerminal)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }.padding(.leading, 8)
    }

    private var toolErrorBlock: some View {
        HStack(alignment: .top, spacing: 0) {
            Text("  x ").font(Theme.mono(11)).foregroundColor(Theme.red)
            Text(block.content)
                .font(Theme.mono(compact ? 10 : 11))
                .foregroundColor(Theme.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, 8)
        .background(Theme.red.opacity(0.04))
    }

    private func toolEndBlock(success: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: success ? "checkmark" : "xmark")
                .font(Theme.mono(8, weight: .bold))
                .foregroundColor(success ? Theme.green : Theme.red)
        }
        .padding(.leading, 16).padding(.vertical, 1)
    }

    private func fileChangeBlock(action: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: action == "Write" ? "doc.badge.plus" : "pencil.line")
                .font(.system(size: 9)).foregroundColor(Theme.green)
            Text(action).font(Theme.mono(10, weight: .semibold)).foregroundColor(Theme.green)
            Text(block.content).font(Theme.mono(compact ? 10 : 11)).foregroundColor(Theme.textPrimary)
        }
        .padding(.vertical, 3).padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(Theme.green.opacity(0.06)))
    }

    private func statusBlock(_ msg: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "info.circle").font(.system(size: 7)).foregroundColor(Theme.textDim)
            Text(msg).font(Theme.monoTiny).foregroundColor(Theme.textDim).italic()
        }.padding(.vertical, 1)
    }

    private func completionBlock(cost: Double?, duration: Int?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // 완료 헤더
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 14)).foregroundColor(Theme.green)
                Text("완료").font(Theme.mono(12, weight: .bold)).foregroundColor(Theme.green)
                Spacer()
                HStack(spacing: 8) {
                    if let d = duration {
                        HStack(spacing: 3) {
                            Image(systemName: "clock").font(.system(size: 8)).foregroundColor(Theme.textDim)
                            Text("\(d/1000).\(d%1000/100)s").font(Theme.mono(9)).foregroundColor(Theme.textDim)
                        }
                    }
                    if let c = cost, c > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "dollarsign.circle").font(.system(size: 8)).foregroundColor(Theme.yellow)
                            Text(String(format: "$%.4f", c)).font(Theme.mono(9, weight: .semibold)).foregroundColor(Theme.yellow)
                        }
                    }
                }
            }

            // 결과 내용 (마크다운 렌더링)
            if !block.content.isEmpty && block.content != "완료" {
                Rectangle().fill(Theme.green.opacity(0.15)).frame(height: 1)
                MarkdownTextView(text: block.content, compact: compact)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Theme.bgSurface.opacity(0.6)))
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, 8).padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8).fill(Theme.green.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.green.opacity(0.15), lineWidth: 0.5))
        )
    }

    private func errorBlock(_ msg: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 10)).foregroundColor(Theme.red)
            Text(msg).font(Theme.mono(11)).foregroundColor(Theme.red)
            if !block.content.isEmpty { Text(block.content).font(Theme.monoSmall).foregroundColor(Theme.red.opacity(0.7)) }
        }
        .padding(.vertical, 4).padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(Theme.red.opacity(0.05)))
    }

    private var textBlock: some View {
        Text(block.content).font(Theme.mono(compact ? 11 : 12)).foregroundColor(Theme.textTerminal)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func toolColor(_ name: String) -> Color {
        switch name {
        case "Bash": return Theme.yellow
        case "Read": return Theme.accent
        case "Write", "Edit": return Theme.green
        case "Grep", "Glob": return Theme.cyan
        case "Agent": return Theme.purple
        default: return Theme.textSecondary
        }
    }
}

// ═══════════════════════════════════════════════════════
// MARK: - Markdown Text View
// ═══════════════════════════════════════════════════════

struct MarkdownTextView: View {
    let text: String
    let compact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(parseBlocks().enumerated()), id: \.offset) { _, mdBlock in
                switch mdBlock {
                case .heading(let level, let content):
                    Text(content)
                        .font(Theme.mono(headingSize(level), weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                        .padding(.top, level <= 2 ? 6 : 3)
                case .codeBlock(let code):
                    Text(code)
                        .font(Theme.mono(compact ? 10 : 11))
                        .foregroundColor(Theme.cyan)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Theme.bg))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border.opacity(0.5), lineWidth: 0.5))
                        .textSelection(.enabled)
                case .bullet(let content):
                    HStack(alignment: .top, spacing: 6) {
                        Text("•").font(Theme.mono(compact ? 10 : 11)).foregroundColor(Theme.accent)
                            .frame(width: 10)
                        inlineMarkdown(content)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                case .separator:
                    Rectangle().fill(Theme.border).frame(height: 1).padding(.vertical, 4)
                case .table(let rows):
                    tableView(rows)
                case .paragraph(let content):
                    inlineMarkdown(content)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Inline markdown (bold, code, italic)

    private func inlineMarkdown(_ text: String) -> Text {
        var result = Text("")
        var remaining = text[text.startIndex...]

        while !remaining.isEmpty {
            // **bold**
            if let boldRange = remaining.range(of: "\\*\\*(.+?)\\*\\*", options: .regularExpression) {
                let before = remaining[remaining.startIndex..<boldRange.lowerBound]
                if !before.isEmpty { result = result + Text(before).font(Theme.mono(compact ? 11 : 12)).foregroundColor(Theme.textSecondary) }
                var inner = String(remaining[boldRange])
                inner.removeFirst(2); inner.removeLast(2)
                result = result + Text(inner).font(Theme.mono(compact ? 11 : 12, weight: .bold)).foregroundColor(Theme.textPrimary)
                remaining = remaining[boldRange.upperBound...]
            }
            // `code`
            else if let codeRange = remaining.range(of: "`([^`]+)`", options: .regularExpression) {
                let before = remaining[remaining.startIndex..<codeRange.lowerBound]
                if !before.isEmpty { result = result + Text(before).font(Theme.mono(compact ? 11 : 12)).foregroundColor(Theme.textSecondary) }
                var inner = String(remaining[codeRange])
                inner.removeFirst(1); inner.removeLast(1)
                result = result + Text(inner).font(Theme.mono(compact ? 10 : 11)).foregroundColor(Theme.cyan)
                remaining = remaining[codeRange.upperBound...]
            }
            else {
                result = result + Text(remaining).font(Theme.mono(compact ? 11 : 12)).foregroundColor(Theme.textSecondary)
                break
            }
        }
        return result
    }

    // MARK: - Table

    private func tableView(_ rows: [[String]]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIdx, row in
                HStack(spacing: 0) {
                    ForEach(Array(row.enumerated()), id: \.offset) { colIdx, cell in
                        Text(cell.trimmingCharacters(in: .whitespaces))
                            .font(Theme.mono(compact ? 9 : 10, weight: rowIdx == 0 ? .bold : .regular))
                            .foregroundColor(rowIdx == 0 ? Theme.textPrimary : Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                        if colIdx < row.count - 1 {
                            Rectangle().fill(Theme.border.opacity(0.3)).frame(width: 1)
                        }
                    }
                }
                if rowIdx == 0 {
                    Rectangle().fill(Theme.border).frame(height: 1)
                } else if rowIdx < rows.count - 1 {
                    Rectangle().fill(Theme.border.opacity(0.3)).frame(height: 1)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 6).fill(Theme.bgSurface.opacity(0.5)))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border.opacity(0.5), lineWidth: 0.5))
    }

    // MARK: - Block Parser

    private enum MdBlock {
        case heading(Int, String)
        case codeBlock(String)
        case bullet(String)
        case separator
        case table([[String]])
        case paragraph(String)
    }

    private func headingSize(_ level: Int) -> CGFloat {
        switch level {
        case 1: return compact ? 14 : 16
        case 2: return compact ? 13 : 14
        case 3: return compact ? 12 : 13
        default: return compact ? 11 : 12
        }
    }

    private func parseBlocks() -> [MdBlock] {
        let lines = text.components(separatedBy: "\n")
        var blocks: [MdBlock] = []
        var i = 0

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Code block
            if trimmed.hasPrefix("```") {
                var code: [String] = []
                i += 1
                while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    code.append(lines[i])
                    i += 1
                }
                blocks.append(.codeBlock(code.joined(separator: "\n")))
                i += 1
                continue
            }

            // Heading
            if trimmed.hasPrefix("###") {
                blocks.append(.heading(3, String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)))
                i += 1; continue
            }
            if trimmed.hasPrefix("##") {
                blocks.append(.heading(2, String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)))
                i += 1; continue
            }
            if trimmed.hasPrefix("#") {
                blocks.append(.heading(1, String(trimmed.dropFirst(1)).trimmingCharacters(in: .whitespaces)))
                i += 1; continue
            }

            // Separator
            if trimmed.hasPrefix("---") || trimmed.hasPrefix("***") {
                blocks.append(.separator)
                i += 1; continue
            }

            // Table (detect | at start)
            if trimmed.hasPrefix("|") && trimmed.contains("|") {
                var tableRows: [[String]] = []
                while i < lines.count {
                    let tl = lines[i].trimmingCharacters(in: .whitespaces)
                    guard tl.hasPrefix("|") else { break }
                    // skip separator rows like |---|---|
                    if tl.contains("---") { i += 1; continue }
                    let cells = tl.components(separatedBy: "|").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    if !cells.isEmpty { tableRows.append(cells) }
                    i += 1
                }
                if !tableRows.isEmpty { blocks.append(.table(tableRows)) }
                continue
            }

            // Bullet
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                let content = String(trimmed.dropFirst(2))
                blocks.append(.bullet(content))
                i += 1; continue
            }

            // Empty line
            if trimmed.isEmpty {
                i += 1; continue
            }

            // Paragraph (collect consecutive non-empty lines)
            var para: [String] = [line]
            i += 1
            while i < lines.count {
                let next = lines[i].trimmingCharacters(in: .whitespaces)
                if next.isEmpty || next.hasPrefix("#") || next.hasPrefix("```") || next.hasPrefix("|") || next.hasPrefix("- ") || next.hasPrefix("* ") || next.hasPrefix("---") { break }
                para.append(lines[i])
                i += 1
            }
            blocks.append(.paragraph(para.joined(separator: "\n")))
        }
        return blocks
    }
}

// ═══════════════════════════════════════════════════════
// MARK: - Processing Indicator
// ═══════════════════════════════════════════════════════

struct ProcessingIndicator: View {
    let activity: ClaudeActivity
    let workerColor: Color
    let workerName: String
    @ObservedObject private var settings = AppSettings.shared
    @State private var dotPhase = 0
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(workerColor).frame(width: 8, height: 8)
            Text(workerName).font(Theme.mono(10, weight: .semibold)).foregroundColor(workerColor)
            Text(statusText).font(Theme.monoSmall).foregroundColor(Theme.textDim)
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { i in
                    Circle().fill(Theme.textDim)
                        .frame(width: 3, height: 3)
                        .opacity(i <= dotPhase ? 0.8 : 0.2)
                }
            }
        }
        .padding(.vertical, 4)
        .onReceive(timer) { _ in dotPhase = (dotPhase + 1) % 3 }
    }

    private var statusText: String {
        switch activity {
        case .thinking: return "생각 중"
        case .reading: return "읽는 중"
        case .writing: return "작성 중"
        case .searching: return "검색 중"
        case .running: return "실행 중"
        default: return "처리 중"
        }
    }
}

// ═══════════════════════════════════════════════════════
// MARK: - Grid Panel View
// ═══════════════════════════════════════════════════════

struct GridPanelView: View {
    @EnvironmentObject var manager: SessionManager

    private var visibleGroups: [SessionManager.ProjectGroup] {
        if let selectedPath = manager.selectedGroupPath {
            let tabs = manager.visibleTabs
            guard let first = tabs.first else { return [] }
            return [SessionManager.ProjectGroup(id: selectedPath, projectName: first.projectName, tabs: tabs, hasActiveTab: tabs.contains(where: { $0.id == manager.activeTabId }))]
        }
        return manager.projectGroups
    }

    private var isFiltered: Bool { manager.selectedGroupPath != nil }

    var body: some View {
        if manager.visibleTabs.isEmpty {
            EmptySessionView()
        } else if manager.focusSingleTab, let tab = manager.activeTab {
            // 개별 워커 포커스: 한 명만 풀사이즈로
            EventStreamView(tab: tab, compact: false)
        } else {
            let groups = visibleGroups
            let tabCount = groups.reduce(0) { $0 + $1.tabs.count }
            let cols = tabCount <= 1 ? 1 : tabCount <= 4 ? 2 : 3
            GeometryReader { geo in
                let totalH = geo.size.height
                let rows = Int(ceil(Double(tabCount) / Double(cols)))
                let cellH = max(120, (totalH - CGFloat(rows + 1) * 6) / CGFloat(rows))
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: cols), spacing: 6) {
                        ForEach(groups) { group in
                            if isFiltered && group.tabs.count > 1 {
                                ForEach(group.tabs) { tab in
                                    GridSinglePanel(tab: tab, isSelected: manager.activeTabId == tab.id)
                                        .frame(height: cellH)
                                        .onTapGesture { manager.focusSingleTab = true; manager.selectTab(tab.id) }
                                }
                            } else {
                                GridGroupPanel(group: group)
                                    .frame(height: cellH)
                            }
                        }
                    }.padding(6)
                }.background(Theme.bg)
            }
        }
    }
}

// 선택된 그룹 내 개별 탭 패널
struct GridSinglePanel: View {
    @ObservedObject var tab: TerminalTab
    @ObservedObject private var settings = AppSettings.shared
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 1).fill(tab.workerColor).frame(width: 3, height: 12)
                Text(tab.workerName).font(Theme.mono(9, weight: .bold)).foregroundColor(tab.workerColor)
                Text(tab.projectName).font(Theme.mono(9)).foregroundColor(Theme.textSecondary).lineLimit(1)
                Spacer()
                if tab.isProcessing { ProgressView().scaleEffect(0.35).frame(width: 8, height: 8) }
                Text(tab.selectedModel.icon).font(Theme.monoTiny)
            }
            .padding(.horizontal, 6).padding(.vertical, 4)
            .background(isSelected ? Theme.bgSelected : Theme.bgCard)

            EventStreamView(tab: tab, compact: true)
        }
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgCard))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Theme.accent.opacity(0.5) : Theme.border, lineWidth: isSelected ? 1.5 : 0.5))
    }
}

struct GridGroupPanel: View {
    let group: SessionManager.ProjectGroup
    @EnvironmentObject var manager: SessionManager
    @ObservedObject private var settings = AppSettings.shared
    @State private var selectedWorkerIndex = 0

    private var activeTab: TerminalTab {
        let idx = min(max(0, selectedWorkerIndex), max(0, group.tabs.count - 1))
        return group.tabs.isEmpty ? group.tabs[0] : group.tabs[idx]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header: project name + worker tabs
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 1).fill(activeTab.workerColor).frame(width: 3, height: 12)
                Text(group.projectName).font(Theme.mono(10, weight: .semibold)).foregroundColor(Theme.textPrimary).lineLimit(1)
                Spacer()

                if group.tabs.count > 1 {
                    // Worker tab selector
                    HStack(spacing: 2) {
                        ForEach(Array(group.tabs.enumerated()), id: \.element.id) { i, tab in
                            Button(action: { selectedWorkerIndex = i; manager.selectTab(tab.id) }) {
                                Text(tab.workerName).font(Theme.mono(7, weight: selectedWorkerIndex == i ? .bold : .regular))
                                    .foregroundColor(selectedWorkerIndex == i ? tab.workerColor : Theme.textDim)
                                    .padding(.horizontal, 4).padding(.vertical, 2)
                                    .background(selectedWorkerIndex == i ? tab.workerColor.opacity(0.1) : .clear)
                                    .cornerRadius(3)
                            }.buttonStyle(.plain)
                        }
                    }
                }

                if activeTab.isProcessing { ProgressView().scaleEffect(0.35).frame(width: 8, height: 8) }
                Text(activeTab.selectedModel.icon).font(Theme.monoTiny)
            }
            .padding(.horizontal, 6).padding(.vertical, 4)
            .background(group.hasActiveTab ? Theme.bgSelected : Theme.bgCard)

            EventStreamView(tab: activeTab, compact: true)
        }
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgCard))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(group.hasActiveTab ? Theme.accent.opacity(0.5) : Theme.border, lineWidth: group.hasActiveTab ? 1.5 : 0.5))
        .onTapGesture { manager.selectTab(activeTab.id) }
    }
}

// ═══════════════════════════════════════════════════════
// MARK: - [Feature 5] Approval Sheet
// ═══════════════════════════════════════════════════════

struct ApprovalSheet: View {
    let approval: TerminalTab.PendingApproval
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.shield.fill").font(.system(size: 20)).foregroundColor(Theme.yellow)
                Text("승인 필요").font(Theme.mono(14, weight: .bold)).foregroundColor(Theme.textPrimary)
            }
            Text(approval.reason).font(Theme.monoSmall).foregroundColor(Theme.textSecondary)
            Text(approval.command).font(Theme.mono(11)).foregroundColor(Theme.red)
                .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 6).fill(Theme.red.opacity(0.05)))
                .textSelection(.enabled)
            HStack {
                Button(action: { approval.onDeny?(); dismiss() }) {
                    Text("거부").font(Theme.mono(11, weight: .medium)).foregroundColor(Theme.red)
                        .padding(.horizontal, 20).padding(.vertical, 8)
                        .background(Theme.red.opacity(0.1)).cornerRadius(6)
                }.buttonStyle(.plain).keyboardShortcut(.escape)
                Spacer()
                Button(action: { approval.onApprove?(); dismiss() }) {
                    Text("승인").font(Theme.mono(11, weight: .medium)).foregroundColor(.white)
                        .padding(.horizontal, 20).padding(.vertical, 8)
                        .background(Theme.accent).cornerRadius(6)
                }.buttonStyle(.plain).keyboardShortcut(.return)
            }
        }.padding(24).frame(width: 420).background(Theme.bgCard)
    }
}

// ═══════════════════════════════════════════════════════
// MARK: - Supporting Views
// ═══════════════════════════════════════════════════════

struct EmptySessionView: View {
    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "hammer.fill").font(.system(size: 28)).foregroundColor(Theme.textDim.opacity(0.3))
            Text("Cmd+T to start").font(.system(size: 10, design: .monospaced)).foregroundColor(Theme.textDim)
            Spacer()
        }.frame(maxWidth: .infinity).background(Theme.bgTerminal)
    }
}

// ═══════════════════════════════════════════════════════
// MARK: - New Tab Sheet (멀티 터미널 지원)
// ═══════════════════════════════════════════════════════

struct NewTabSheet: View {
    @EnvironmentObject var manager: SessionManager; @Environment(\.dismiss) var dismiss
    @State private var projectName = ""
    @State private var projectPath = ""
    @State private var terminalCount = 1
    @State private var tasks: [String] = [""]

    // 폴더 신뢰 확인
    @State private var trustConfirmed = false

    // 고급 옵션
    @State private var showAdvanced = false
    @State private var permissionMode: PermissionMode = .bypassPermissions
    @State private var systemPrompt = ""
    @State private var maxBudget: String = ""
    @State private var allowedTools = ""
    @State private var disallowedTools = ""
    @State private var additionalDir = ""
    @State private var additionalDirs: [String] = []
    @State private var continueSession = false
    @State private var useWorktree = false
    @State private var selectedModel: ClaudeModel = .sonnet
    @State private var effortLevel: EffortLevel = .medium

    var body: some View {
        if !trustConfirmed && !projectPath.isEmpty {
            trustPromptView
        } else {
            sessionConfigView
        }
    }

    // MARK: - 폴더 신뢰 확인 화면

    private var trustPromptView: some View {
        VStack(spacing: 0) {
            // 터미널 스타일 헤더
            VStack(spacing: 12) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 28)).foregroundColor(Theme.yellow)

                Text("폴더 신뢰 확인")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
            }.padding(.top, 20).padding(.bottom, 12)

            // 경로 표시
            HStack(spacing: 6) {
                Image(systemName: "folder.fill").font(.system(size: 10)).foregroundColor(Theme.accent)
                Text(projectPath)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Theme.accent).lineLimit(1).truncationMode(.middle)
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.accent.opacity(0.06)))
            .padding(.horizontal, 24)

            // 안내 텍스트
            VStack(alignment: .leading, spacing: 8) {
                Text("이 프로젝트를 직접 만들었거나 신뢰할 수 있나요?")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)

                Text("(직접 작성한 코드, 잘 알려진 오픈소스, 또는 팀 프로젝트 등)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(Theme.textDim)

                Rectangle().fill(Theme.border).frame(height: 1).padding(.vertical, 4)

                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 9)).foregroundColor(Theme.yellow)
                    Text("Claude Code가 이 폴더의 파일을 읽고, 수정하고, 실행할 수 있습니다.")
                        .font(.system(size: 9, design: .monospaced)).foregroundColor(Theme.yellow)
                }
            }
            .padding(16).padding(.horizontal, 8)

            Spacer(minLength: 8)

            // 선택 버튼
            VStack(spacing: 6) {
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { trustConfirmed = true } }) {
                    HStack(spacing: 8) {
                        Text("❯").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(Theme.green)
                        Text("네, 이 폴더를 신뢰합니다")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced)).foregroundColor(Theme.textPrimary)
                        Spacer()
                        Image(systemName: "checkmark.shield.fill").font(.system(size: 12)).foregroundColor(Theme.green)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.green.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.green.opacity(0.3), lineWidth: 1)))
                }.buttonStyle(.plain).keyboardShortcut(.return)

                Button(action: { dismiss() }) {
                    HStack(spacing: 8) {
                        Text(" ").font(.system(size: 12, weight: .bold, design: .monospaced))
                        Text("아니오, 나가기")
                            .font(.system(size: 11, design: .monospaced)).foregroundColor(Theme.textSecondary)
                        Spacer()
                        Image(systemName: "xmark.circle").font(.system(size: 12)).foregroundColor(Theme.textDim)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border.opacity(0.3), lineWidth: 1)))
                }.buttonStyle(.plain).keyboardShortcut(.escape)
            }.padding(.horizontal, 24).padding(.bottom, 20)
        }
        .frame(width: 440, height: 340).background(Theme.bgCard)
    }

    // MARK: - 세션 설정 화면

    private var sessionConfigView: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    // Header
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill").font(.system(size: 14)).foregroundColor(Theme.accent)
                        Text("New Session").font(.system(size: 13, weight: .semibold, design: .monospaced)).foregroundColor(Theme.textPrimary)
                    }

                    // Project info
                    VStack(alignment: .leading, spacing: 5) {
                        Text("PROJECT PATH").font(Theme.pixel).foregroundColor(Theme.textDim).tracking(1.5)
                        HStack {
                            TextField("/path/to/project", text: $projectPath).textFieldStyle(.roundedBorder).font(Theme.monoSmall)
                            Button("Browse") {
                                let p = NSOpenPanel(); p.canChooseFiles = false; p.canChooseDirectories = true
                                if p.runModal() == .OK, let u = p.url {
                                    projectPath = u.path
                                    if projectName.isEmpty { projectName = u.lastPathComponent }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text("PROJECT NAME").font(Theme.pixel).foregroundColor(Theme.textDim).tracking(1.5)
                        TextField("e.g. my-project", text: $projectName).textFieldStyle(.roundedBorder).font(Theme.monoSmall)
                    }

                    // Model & Effort
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("MODEL").font(Theme.pixel).foregroundColor(Theme.textDim).tracking(1.5)
                            HStack(spacing: 3) {
                                ForEach(ClaudeModel.allCases) { m in
                                    Button(action: { selectedModel = m }) {
                                        Text("\(m.icon) \(m.displayName)")
                                            .font(.system(size: 9, weight: selectedModel == m ? .bold : .regular, design: .monospaced))
                                            .foregroundColor(selectedModel == m ? Theme.textPrimary : Theme.textDim)
                                            .padding(.horizontal, 8).padding(.vertical, 5)
                                            .background(RoundedRectangle(cornerRadius: 5)
                                                .fill(selectedModel == m ? Theme.accent.opacity(0.12) : Theme.bgSurface)
                                                .overlay(RoundedRectangle(cornerRadius: 5)
                                                    .stroke(selectedModel == m ? Theme.accent.opacity(0.4) : Theme.border.opacity(0.3), lineWidth: 1)))
                                    }.buttonStyle(.plain)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            Text("EFFORT").font(Theme.pixel).foregroundColor(Theme.textDim).tracking(1.5)
                            HStack(spacing: 3) {
                                ForEach(EffortLevel.allCases) { l in
                                    Button(action: { effortLevel = l }) {
                                        Text("\(l.icon)")
                                            .font(.system(size: 10))
                                            .padding(.horizontal, 6).padding(.vertical, 5)
                                            .background(RoundedRectangle(cornerRadius: 5)
                                                .fill(effortLevel == l ? Theme.accent.opacity(0.12) : Theme.bgSurface)
                                                .overlay(RoundedRectangle(cornerRadius: 5)
                                                    .stroke(effortLevel == l ? Theme.accent.opacity(0.4) : Theme.border.opacity(0.3), lineWidth: 1)))
                                    }.buttonStyle(.plain).help(l.rawValue.capitalized)
                                }
                            }
                        }
                    }

                    // Permission mode
                    VStack(alignment: .leading, spacing: 5) {
                        Text("PERMISSION").font(Theme.pixel).foregroundColor(Theme.textDim).tracking(1.5)
                        HStack(spacing: 3) {
                            ForEach(PermissionMode.allCases) { m in
                                Button(action: { permissionMode = m }) {
                                    Text("\(m.icon) \(m.displayName)")
                                        .font(.system(size: 9, weight: permissionMode == m ? .bold : .regular, design: .monospaced))
                                        .foregroundColor(permissionMode == m ? Theme.textPrimary : Theme.textDim)
                                        .padding(.horizontal, 7).padding(.vertical, 5)
                                        .background(RoundedRectangle(cornerRadius: 5)
                                            .fill(permissionMode == m ? Theme.purple.opacity(0.1) : Theme.bgSurface)
                                            .overlay(RoundedRectangle(cornerRadius: 5)
                                                .stroke(permissionMode == m ? Theme.purple.opacity(0.4) : Theme.border.opacity(0.3), lineWidth: 1)))
                                }.buttonStyle(.plain).help(m.desc)
                            }
                        }
                    }

                    // Terminal count
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("TERMINALS").font(Theme.pixel).foregroundColor(Theme.textDim).tracking(1.5)
                            Spacer()
                            Text("\(terminalCount)개").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(Theme.accent)
                        }
                        HStack(spacing: 4) {
                            ForEach([1, 2, 3, 4, 5], id: \.self) { n in
                                Button(action: { withAnimation(.easeInOut(duration: 0.15)) { setTerminalCount(n) } }) {
                                    VStack(spacing: 2) {
                                        HStack(spacing: 1) {
                                            ForEach(0..<n, id: \.self) { i in
                                                let colorIdx = (manager.tabs.count + i) % Theme.workerColors.count
                                                RoundedRectangle(cornerRadius: 1).fill(Theme.workerColors[colorIdx])
                                                    .frame(width: n <= 3 ? 10 : 6, height: 14)
                                            }
                                        }
                                        Text("\(n)").font(.system(size: 9, weight: terminalCount == n ? .bold : .regular, design: .monospaced))
                                            .foregroundColor(terminalCount == n ? Theme.accent : Theme.textDim)
                                    }
                                    .padding(.horizontal, 8).padding(.vertical, 6)
                                    .background(RoundedRectangle(cornerRadius: 6)
                                        .fill(terminalCount == n ? Theme.accent.opacity(0.1) : Theme.bgSurface)
                                        .overlay(RoundedRectangle(cornerRadius: 6)
                                            .stroke(terminalCount == n ? Theme.accent.opacity(0.4) : Theme.border.opacity(0.5), lineWidth: 1)))
                                }.buttonStyle(.plain)
                            }
                        }

                        if terminalCount > 1 {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("각 터미널에 보낼 작업 (선택)").font(.system(size: 9, design: .monospaced)).foregroundColor(Theme.textDim)
                                ForEach(tasks.indices, id: \.self) { i in
                                    HStack(spacing: 6) {
                                        let colorIdx = (manager.tabs.count + i) % Theme.workerColors.count
                                        Circle().fill(Theme.workerColors[colorIdx]).frame(width: 8, height: 8)
                                        Text("#\(i + 1)").font(.system(size: 8, weight: .bold, design: .monospaced))
                                            .foregroundColor(Theme.textDim).frame(width: 18)
                                        TextField("작업 내용 (비워두면 빈 터미널)", text: $tasks[i])
                                            .textFieldStyle(.roundedBorder).font(.system(size: 10, design: .monospaced))
                                    }
                                }
                            }.padding(.top, 4)
                        }
                    }

                    // ── 고급 옵션 토글 ──
                    Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showAdvanced.toggle() } }) {
                        HStack(spacing: 6) {
                            Image(systemName: showAdvanced ? "chevron.down" : "chevron.right")
                                .font(.system(size: 8, weight: .bold)).foregroundColor(Theme.textDim)
                            Text("고급 옵션").font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundColor(Theme.textSecondary)
                            Spacer()
                            if hasAdvancedOptions {
                                Text("설정됨").font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundColor(Theme.green)
                                    .padding(.horizontal, 5).padding(.vertical, 2)
                                    .background(Theme.green.opacity(0.1)).cornerRadius(3)
                            }
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Theme.bgSurface.opacity(0.5))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border.opacity(0.3), lineWidth: 0.5)))
                    }.buttonStyle(.plain)

                    if showAdvanced {
                        advancedOptionsView
                    }
                }.padding(24)
            }

            // Buttons
            HStack {
                Button("Cancel") { dismiss() }.keyboardShortcut(.escape)
                Spacer()
                Button(action: {
                    if !projectPath.isEmpty && !trustConfirmed {
                        trustConfirmed = false // trigger trust prompt
                    } else {
                        createSessions(); dismiss()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill").font(.system(size: 9))
                        Text(terminalCount > 1 ? "Create \(terminalCount)개" : "Create")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 6)
                    .background(Theme.accent).cornerRadius(6)
                }
                .buttonStyle(.plain).keyboardShortcut(.return)
                .disabled(projectPath.isEmpty && projectName.isEmpty)
            }.padding(.horizontal, 24).padding(.vertical, 12)
            .background(Theme.bgCard)
            .overlay(Rectangle().fill(Theme.border).frame(height: 1), alignment: .top)
        }
        .frame(width: 500, height: 580).background(Theme.bgCard)
    }

    // MARK: - 고급 옵션

    private var hasAdvancedOptions: Bool {
        !systemPrompt.isEmpty || maxBudget != "" || !allowedTools.isEmpty ||
        !disallowedTools.isEmpty || !additionalDirs.isEmpty || continueSession || useWorktree
    }

    private var advancedOptionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 시스템 프롬프트
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "text.bubble.fill").font(.system(size: 9)).foregroundColor(Theme.purple)
                    Text("시스템 프롬프트").font(.system(size: 9, weight: .medium, design: .monospaced)).foregroundColor(Theme.textSecondary)
                }
                TextField("추가 지시사항 (--append-system-prompt)", text: $systemPrompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder).font(.system(size: 10, design: .monospaced)).lineLimit(2...4)
            }

            // 예산 제한
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill").font(.system(size: 9)).foregroundColor(Theme.yellow)
                        Text("예산 한도 (USD)").font(.system(size: 9, weight: .medium, design: .monospaced)).foregroundColor(Theme.textSecondary)
                    }
                    TextField("0 = 무제한", text: $maxBudget)
                        .textFieldStyle(.roundedBorder).font(.system(size: 10, design: .monospaced)).frame(width: 100)
                }
                Spacer()

                // 세션 이어하기
                VStack(alignment: .leading, spacing: 4) {
                    Toggle(isOn: $continueSession) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.turn.up.right").font(.system(size: 9)).foregroundColor(Theme.cyan)
                            Text("이전 대화 이어하기").font(.system(size: 9, weight: .medium, design: .monospaced)).foregroundColor(Theme.textSecondary)
                        }
                    }.toggleStyle(.switch).controlSize(.small)
                }
            }

            // 워크트리
            Toggle(isOn: $useWorktree) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.branch").font(.system(size: 9)).foregroundColor(Theme.green)
                    Text("Git 워크트리 생성").font(.system(size: 9, weight: .medium, design: .monospaced)).foregroundColor(Theme.textSecondary)
                    Text("--worktree").font(.system(size: 8, design: .monospaced)).foregroundColor(Theme.textDim)
                }
            }.toggleStyle(.switch).controlSize(.small)

            // 도구 제한
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "wrench.and.screwdriver.fill").font(.system(size: 9)).foregroundColor(Theme.orange)
                    Text("허용 도구").font(.system(size: 9, weight: .medium, design: .monospaced)).foregroundColor(Theme.textSecondary)
                    Text("(쉼표 구분)").font(.system(size: 8, design: .monospaced)).foregroundColor(Theme.textDim)
                }
                TextField("예: Bash,Read,Edit,Write", text: $allowedTools)
                    .textFieldStyle(.roundedBorder).font(.system(size: 10, design: .monospaced))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.shield.fill").font(.system(size: 9)).foregroundColor(Theme.red)
                    Text("차단 도구").font(.system(size: 9, weight: .medium, design: .monospaced)).foregroundColor(Theme.textSecondary)
                    Text("(쉼표 구분)").font(.system(size: 8, design: .monospaced)).foregroundColor(Theme.textDim)
                }
                TextField("예: Bash(rm:*)", text: $disallowedTools)
                    .textFieldStyle(.roundedBorder).font(.system(size: 10, design: .monospaced))
            }

            // 추가 디렉토리
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "folder.badge.plus").font(.system(size: 9)).foregroundColor(Theme.accent)
                    Text("추가 디렉토리 접근").font(.system(size: 9, weight: .medium, design: .monospaced)).foregroundColor(Theme.textSecondary)
                }
                HStack(spacing: 4) {
                    TextField("경로 추가", text: $additionalDir)
                        .textFieldStyle(.roundedBorder).font(.system(size: 10, design: .monospaced))
                    Button(action: {
                        let p = NSOpenPanel(); p.canChooseFiles = false; p.canChooseDirectories = true
                        if p.runModal() == .OK, let u = p.url { additionalDir = u.path }
                    }) {
                        Image(systemName: "folder").font(.system(size: 10)).foregroundColor(Theme.accent)
                    }.buttonStyle(.plain)
                    Button(action: {
                        if !additionalDir.isEmpty {
                            additionalDirs.append(additionalDir); additionalDir = ""
                        }
                    }) {
                        Image(systemName: "plus.circle.fill").font(.system(size: 12)).foregroundColor(Theme.green)
                    }.buttonStyle(.plain).disabled(additionalDir.isEmpty)
                }
                if !additionalDirs.isEmpty {
                    ForEach(additionalDirs.indices, id: \.self) { i in
                        HStack(spacing: 4) {
                            Image(systemName: "folder.fill").font(.system(size: 8)).foregroundColor(Theme.accent.opacity(0.6))
                            Text(additionalDirs[i]).font(.system(size: 9, design: .monospaced)).foregroundColor(Theme.textSecondary).lineLimit(1)
                            Spacer()
                            Button(action: { additionalDirs.remove(at: i) }) {
                                Image(systemName: "xmark").font(.system(size: 7, weight: .bold)).foregroundColor(Theme.red)
                            }.buttonStyle(.plain)
                        }.padding(.leading, 8)
                    }
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.bgSurface.opacity(0.5))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.3), lineWidth: 0.5)))
    }

    private func setTerminalCount(_ n: Int) {
        terminalCount = n
        while tasks.count < n { tasks.append("") }
        while tasks.count > n { tasks.removeLast() }
    }

    private func createSessions() {
        let name = projectName.isEmpty ? (projectPath as NSString).lastPathComponent : projectName
        let path = projectPath.isEmpty ? NSHomeDirectory() : projectPath

        for i in 0..<terminalCount {
            let prompt = i < tasks.count ? tasks[i].trimmingCharacters(in: .whitespaces) : ""
            manager.addTab(
                projectName: name,
                projectPath: path,
                initialPrompt: prompt.isEmpty ? nil : prompt
            )
            // 마지막으로 추가된 탭에 고급 옵션 적용
            if let tab = manager.tabs.last {
                tab.selectedModel = selectedModel
                tab.effortLevel = effortLevel
                tab.permissionMode = permissionMode
                tab.systemPrompt = systemPrompt
                tab.maxBudgetUSD = Double(maxBudget) ?? 0
                tab.allowedTools = allowedTools
                tab.disallowedTools = disallowedTools
                tab.additionalDirs = additionalDirs
                tab.continueSession = continueSession
                tab.useWorktree = useWorktree
            }
        }
    }
}
