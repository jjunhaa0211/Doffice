import SwiftUI
import DesignSystem

extension EventStreamView {
    // MARK: - Command Suggestions View
    // ═══════════════════════════════════════════

    var commandSuggestionsView: some View {
        let commands = matchingCommands
        let clampedIndex = min(selectedCommandIndex, max(0, commands.count - 1))
        return VStack(alignment: .leading, spacing: 0) {
            Rectangle().fill(Theme.border).frame(height: 1)
            HStack(spacing: 4) {
                Image(systemName: "command").font(Theme.chrome(8)).foregroundStyle(Theme.accentBackground)
                Text(NSLocalizedString("terminal.command.label", comment: "")).font(Theme.chrome(8, weight: .bold)).foregroundStyle(Theme.accentBackground)
                if commands.count < Self.allSlashCommands.count {
                    Text(String(format: NSLocalizedString("terminal.cmd.match.count", comment: ""), commands.count)).font(Theme.chrome(7)).foregroundColor(Theme.textDim)
                }
                Spacer()
                Text(NSLocalizedString("terminal.cmd.suggestion.hint", comment: "")).font(Theme.chrome(7)).foregroundColor(Theme.textDim)
            }
            .padding(.horizontal, 12).padding(.vertical, 4)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(commands.enumerated()), id: \.offset) { idx, cmd in
                            let isSelected = idx == clampedIndex
                            HStack(spacing: 6) {
                                Text("/\(cmd.name)")
                                    .font(Theme.mono(11, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? Theme.accent : Theme.textPrimary)
                                if !cmd.usage.isEmpty {
                                    Text(cmd.usage).font(Theme.mono(9)).foregroundColor(Theme.textDim)
                                }
                                Spacer()
                                Text(cmd.description).font(Theme.mono(9)).foregroundColor(isSelected ? Theme.textSecondary : Theme.textDim)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 5)
                            .background(isSelected ? Theme.accent.opacity(0.12) : .clear)
                            .contentShape(Rectangle())
                            .id(idx)
                            .onTapGesture {
                                inputText = "/\(cmd.name) "
                                selectedCommandIndex = idx
                            }
                        }
                    }
                }
                .frame(maxHeight: 240)
                .onChange(of: selectedCommandIndex) { _, newIdx in
                    withAnimation(.easeOut(duration: 0.1)) { proxy.scrollTo(min(newIdx, commands.count - 1), anchor: .center) }
                }
            }
        }
        .background(Theme.bgSurface)
    }

    func handleCommandKeyNavigation(_ key: KeyPress) -> KeyPress.Result {
        let commands = matchingCommands

        // Escape → 명령어 모드 종료
        if key.key == .escape {
            inputText = ""
            selectedCommandIndex = 0
            return .handled
        }

        guard !commands.isEmpty else { return .ignored }

        if key.key == .upArrow {
            selectedCommandIndex = max(0, selectedCommandIndex - 1)
            return .handled
        } else if key.key == .downArrow {
            selectedCommandIndex = min(commands.count - 1, selectedCommandIndex + 1)
            return .handled
        } else if key.key == .tab {
            let idx = min(selectedCommandIndex, max(0, commands.count - 1))
            guard idx < commands.count else { return .ignored }
            inputText = "/\(commands[idx].name) "
            return .handled
        }
        return .ignored
    }

    var workflowDisplayTab: TerminalTab? {
        if let sourceId = tab.automationSourceTabId,
           let sourceTab = manager.tabs.first(where: { $0.id == sourceId }) {
            return sourceTab
        }
        return tab.workflowTimelineStages.isEmpty ? nil : tab
    }

    var activePlanSelectionRequest: PlanSelectionRequest? {
        guard tab.permissionMode == .plan, !tab.isProcessing else { return nil }

        let lastUserPromptIndex = tab.blocks.lastIndex { block in
            if case .userPrompt = block.blockType { return true }
            return false
        }

        guard let lastUserPromptIndex else { return nil }
        let nextIdx = tab.blocks.index(after: lastUserPromptIndex)
        let responseBlocks = nextIdx < tab.blocks.endIndex ? tab.blocks.suffix(from: nextIdx) : ArraySlice<StreamBlock>()
        let responseText = responseBlocks.compactMap { block -> String? in
            if case .thought = block.blockType {
                return block.content
            }
            return nil
        }
        .joined(separator: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !responseText.isEmpty else { return nil }
        guard let request = PlanSelectionRequest.parse(from: responseText) else { return nil }
        guard !sentPlanSignatures.contains(request.signature) else { return nil }
        return request
    }

    func syncPlanSelectionState(with request: PlanSelectionRequest?) {
        guard let request else {
            planSelectionSignature = ""
            planSelectionDraft = [:]
            return
        }

        guard planSelectionSignature != request.signature else { return }
        planSelectionSignature = request.signature
        planSelectionDraft = [:]
    }

    func planSelectionPanel(_ request: PlanSelectionRequest) -> some View {
        let selectedCount = request.groups.reduce(into: 0) { count, group in
            if planSelectionDraft[group.id] != nil { count += 1 }
        }
        let isComplete = selectedCount == request.groups.count

        return VStack(alignment: .leading, spacing: compact ? 8 : 10) {
            HStack(spacing: 6) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: Theme.iconSize(compact ? 8 : 10)))
                    .foregroundColor(Theme.purple)
                Text(NSLocalizedString("terminal.plan.select", comment: ""))
                    .font(Theme.mono(compact ? 9 : 10, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text("\(selectedCount)/\(request.groups.count)")
                    .font(Theme.mono(compact ? 8 : 9, weight: .semibold))
                    .foregroundColor(isComplete ? Theme.green : Theme.textDim)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background((isComplete ? Theme.green : Theme.bgSelected).opacity(0.12))
                    .cornerRadius(4)
                Spacer()
                if !planSelectionDraft.isEmpty {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.12)) {
                            planSelectionDraft = [:]
                        }
                    }) {
                        Text(NSLocalizedString("terminal.plan.reset", comment: ""))
                            .font(Theme.mono(compact ? 8 : 9))
                            .foregroundColor(Theme.textDim)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let promptLine = request.promptLine {
                Text(promptLine)
                    .font(Theme.mono(compact ? 9 : 10))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(2)
            }

            ForEach(request.groups) { group in
                VStack(alignment: .leading, spacing: 6) {
                    Text(group.title)
                        .font(Theme.mono(compact ? 9 : 10, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(group.options) { option in
                            let isSelected = planSelectionDraft[group.id] == option.key
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.12)) {
                                    planSelectionDraft[group.id] = option.key
                                }
                            }) {
                                HStack(alignment: .top, spacing: 8) {
                                    Text(option.key)
                                        .font(Theme.mono(compact ? 8 : 9, weight: .bold))
                                        .foregroundColor(isSelected ? Theme.bg : Theme.purple)
                                        .frame(width: compact ? 18 : 20, height: compact ? 18 : 20)
                                        .background(
                                            RoundedRectangle(cornerRadius: 5)
                                                .fill(isSelected ? Theme.purple : Theme.purple.opacity(0.12))
                                        )
                                    Text(option.label)
                                        .font(Theme.mono(compact ? 9 : 10))
                                        .foregroundColor(isSelected ? Theme.textPrimary : Theme.textSecondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .multilineTextAlignment(.leading)
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: Theme.iconSize(compact ? 8 : 9)))
                                            .foregroundColor(Theme.green)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(isSelected ? Theme.purple.opacity(0.1) : Theme.bgSurface.opacity(0.65))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isSelected ? Theme.purple.opacity(0.35) : Theme.border.opacity(0.35), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                Button(action: {
                    inputText = request.responseText(from: planSelectionDraft)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { isFocused = true }
                }) {
                    Text(NSLocalizedString("terminal.insert.input", comment: ""))
                        .font(Theme.mono(compact ? 8 : 9, weight: .medium))
                        .foregroundColor(isComplete ? Theme.textPrimary : Theme.textDim)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 7).fill(Theme.bgSurface))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(isComplete ? Theme.border.opacity(0.5) : Theme.border.opacity(0.25), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!isComplete)

                Button(action: {
                    let response = request.responseText(from: planSelectionDraft)
                    guard !response.isEmpty else { return }
                    inputText = ""
                    sentPlanSignatures.insert(request.signature)
                    tab.sendPrompt(response)
                    AchievementManager.shared.addXP(5)
                    AchievementManager.shared.incrementCommand()
                }) {
                    Text(NSLocalizedString("terminal.send.selection", comment: ""))
                        .font(Theme.mono(compact ? 8 : 9, weight: .bold))
                        .foregroundColor(isComplete ? Theme.bg : Theme.textDim)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(isComplete ? Theme.purple : Theme.bgSelected.opacity(0.35))
                        )
                }
                .buttonStyle(.plain)
                .disabled(!isComplete)

                Spacer()
            }
        }
        .padding(.horizontal, compact ? 10 : 14)
        .padding(.vertical, compact ? 8 : 10)
        .background(Theme.bgSurface.opacity(0.72))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.purple.opacity(0.18), lineWidth: 1)
        )
        .padding(.horizontal, compact ? 8 : 12)
        .padding(.top, 8)
        .padding(.bottom, compact ? 2 : 4)
    }

    func workflowProgressBar(_ workflowTab: TerminalTab) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                    .font(Theme.mono(8))
                    .foregroundStyle(Theme.accentBackground)
                Text(NSLocalizedString("terminal.argument.flow", comment: ""))
                    .font(Theme.mono(8, weight: .bold))
                    .foregroundColor(Theme.textDim)
                if let summary = workflowTab.workflowProgressSummary {
                    Text(summary)
                        .font(Theme.mono(8, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(workflowTab.workflowTimelineStages) { stage in
                        workflowStageChip(stage)
                    }
                }
                .padding(.vertical, 1)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Theme.bgSurface.opacity(0.45))
    }

    func workflowStageChip(_ stage: WorkflowStageRecord) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text(stage.role.displayName)
                    .font(Theme.mono(8, weight: .bold))
                    .foregroundColor(stage.state.tint)
                Text(stage.state.label)
                    .font(Theme.mono(7, weight: .semibold))
                    .foregroundColor(stage.state.tint)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(stage.state.tint.opacity(0.12))
                    .cornerRadius(4)
            }

            Text(stage.workerName)
                .font(Theme.mono(9, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)

            Text(stage.handoffLabel)
                .font(Theme.mono(7))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.bgCard.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(stage.state.tint.opacity(0.22), lineWidth: 1)
        )
    }

}
