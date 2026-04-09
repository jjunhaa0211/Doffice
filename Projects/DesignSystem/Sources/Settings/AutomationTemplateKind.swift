import SwiftUI

public enum AutomationTemplateKind: String, CaseIterable, Identifiable {
    case planner
    case designer
    case developerExecution
    case developerRevision
    case reviewer
    case qa
    case reporter
    case sre

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .planner: return NSLocalizedString("template.pipeline.planner", comment: "")
        case .designer: return NSLocalizedString("template.pipeline.designer", comment: "")
        case .developerExecution: return NSLocalizedString("template.pipeline.dev.exec", comment: "")
        case .developerRevision: return NSLocalizedString("template.pipeline.dev.revision", comment: "")
        case .reviewer: return NSLocalizedString("template.pipeline.reviewer", comment: "")
        case .qa: return "QA"
        case .reporter: return NSLocalizedString("template.pipeline.reporter", comment: "")
        case .sre: return "SRE"
        }
    }

    public var shortLabel: String {
        switch self {
        case .developerExecution: return NSLocalizedString("template.pipeline.dev.exec.short", comment: "")
        case .developerRevision: return NSLocalizedString("template.pipeline.dev.revision.short", comment: "")
        default: return displayName
        }
    }

    public var icon: String {
        switch self {
        case .planner: return "list.bullet.rectangle.portrait.fill"
        case .designer: return "paintbrush.pointed.fill"
        case .developerExecution: return "hammer.fill"
        case .developerRevision: return "arrow.triangle.2.circlepath"
        case .reviewer: return "checklist.checked"
        case .qa: return "checkmark.seal.fill"
        case .reporter: return "doc.text.fill"
        case .sre: return "server.rack"
        }
    }

    public var summary: String {
        switch self {
        case .planner: return NSLocalizedString("template.pipeline.planner.desc", comment: "")
        case .designer: return NSLocalizedString("template.pipeline.designer.desc", comment: "")
        case .developerExecution: return NSLocalizedString("template.pipeline.dev.exec.desc", comment: "")
        case .developerRevision: return NSLocalizedString("template.pipeline.dev.revision.desc", comment: "")
        case .reviewer: return NSLocalizedString("template.pipeline.reviewer.desc", comment: "")
        case .qa: return NSLocalizedString("template.pipeline.qa.desc", comment: "")
        case .reporter: return NSLocalizedString("template.pipeline.reporter.desc", comment: "")
        case .sre: return NSLocalizedString("template.pipeline.sre.desc", comment: "")
        }
    }

    public var placeholderTokens: [String] {
        switch self {
        case .planner:
            return ["{{project_name}}", "{{project_path}}", "{{request}}"]
        case .designer:
            return ["{{project_name}}", "{{project_path}}", "{{request}}", "{{plan_summary}}"]
        case .developerExecution:
            return ["{{project_name}}", "{{project_path}}", "{{request}}", "{{plan_summary}}", "{{design_summary}}"]
        case .developerRevision:
            return ["{{project_name}}", "{{project_path}}", "{{request}}", "{{plan_summary}}", "{{design_summary}}", "{{feedback_role}}", "{{feedback}}"]
        case .reviewer:
            return ["{{project_name}}", "{{project_path}}", "{{request}}", "{{plan_summary}}", "{{design_summary}}", "{{dev_summary}}", "{{changed_files}}"]
        case .qa:
            return ["{{project_name}}", "{{project_path}}", "{{request}}", "{{plan_summary}}", "{{design_summary}}", "{{dev_summary}}", "{{review_summary}}", "{{changed_files}}"]
        case .reporter:
            return ["{{project_name}}", "{{report_path}}", "{{request}}", "{{plan_summary}}", "{{design_summary}}", "{{dev_summary}}", "{{review_summary}}", "{{qa_summary}}", "{{validation_summary}}", "{{changed_files}}"]
        case .sre:
            return ["{{project_name}}", "{{project_path}}", "{{request}}", "{{dev_summary}}", "{{qa_summary}}", "{{validation_summary}}", "{{changed_files}}"]
        }
    }

    public var pinnedLines: [String] {
        switch self {
        case .planner:
            return ["PLANNER_STATUS: READY"]
        case .designer:
            return ["DESIGN_STATUS: READY"]
        case .reviewer:
            return ["REVIEW_STATUS: PASS", "REVIEW_STATUS: FAIL", "REVIEW_STATUS: BLOCKED"]
        case .qa:
            return ["QA_STATUS: PASS", "QA_STATUS: FAIL", "QA_STATUS: BLOCKED"]
        case .reporter:
            return ["REPORT_STATUS: WRITTEN", "REPORT_PATH: {{report_path}}"]
        case .sre:
            return ["SRE_STATUS: CHECKED"]
        case .developerExecution, .developerRevision:
            return []
        }
    }

    public var defaultTemplate: String {
        switch self {
        case .planner:
            return """
당신은 도피스의 기획자입니다.
아래 사용자 요구사항을 보고 개발자가 바로 구현할 수 있게 정리하세요.

프로젝트: {{project_name}}
경로: {{project_path}}

사용자 요구사항:
{{request}}

정리 양식:
- 요구사항 한 줄 요약
- 반드시 구현할 핵심 항목
- 수용 기준
- 주의할 점
- 디자이너/개발자 메모
"""
        case .designer:
            return """
당신은 도피스의 디자이너입니다.
아래 요구사항과 기획 요약을 바탕으로 UI/UX, 상호작용, 화면 흐름 관점의 정리본을 만들어 주세요.

프로젝트: {{project_name}}
경로: {{project_path}}

원래 요구사항:
{{request}}

기획 요약:
{{plan_summary}}

정리 양식:
- 화면/상태 흐름
- 사용자 경험상 주의할 점
- edge case
- 개발 메모
"""
        case .developerExecution:
            return """
아래 요구사항을 구현하세요.

프로젝트: {{project_name}}
경로: {{project_path}}

원래 요구사항:
{{request}}

기획 요약:
{{plan_summary}}

디자인/경험 메모:
{{design_summary}}

구현 지침:
1. 필요한 코드를 직접 수정하세요.
2. 변경 파일과 검증 결과를 명확히 남기세요.
3. 작업을 마치면 완료 요약을 짧게 정리하세요.
"""
        case .developerRevision:
            return """
아래 요구사항을 다시 구현하세요.

프로젝트: {{project_name}}
경로: {{project_path}}

원래 요구사항:
{{request}}

기획 요약:
{{plan_summary}}

디자인/경험 메모:
{{design_summary}}

추가 수정 피드백 ({{feedback_role}}):
{{feedback}}

재작업 지침:
1. 피드백을 반영해 필요한 코드를 직접 수정하세요.
2. 어떤 점을 고쳤는지 완료 요약에 꼭 포함하세요.
3. 검증 결과까지 함께 남기세요.
"""
        case .reviewer:
            return """
당신은 도피스의 코드 리뷰어입니다.
아래 개발 작업이 완료되었고 코드 수정도 발생했습니다. 코드는 수정하지 말고, 변경 내용과 리스크를 검토하세요.

프로젝트: {{project_name}}
경로: {{project_path}}

최근 요구사항:
{{request}}

기획 요약:
{{plan_summary}}

디자인 요약:
{{design_summary}}

개발 완료 요약:
{{dev_summary}}

변경된 파일:
{{changed_files}}

검토 양식:
- 핵심 findings
- 테스트/검증 부족
- 오픈 질문 또는 우려점
- 최종 판단
"""
        case .qa:
            return """
당신은 도피스의 QA 담당자입니다.
아래 개발 작업이 완료되었습니다. 변경된 흐름을 직접 실행/테스트해 검증하세요.

프로젝트: {{project_name}}
경로: {{project_path}}

최근 요구사항:
{{request}}

기획 요약:
{{plan_summary}}

디자인 요약:
{{design_summary}}

개발 완료 요약:
{{dev_summary}}

코드 리뷰 요약:
{{review_summary}}

변경된 파일:
{{changed_files}}

검증 양식:
- 실제로 실행/테스트한 항목
- 확인 결과
- 재현 단계 또는 관찰 내용
- 남은 리스크
- 최종 판단
"""
        case .reporter:
            return """
당신은 도피스의 보고자입니다.
최종 Markdown 보고서를 작성하세요.

프로젝트: {{project_name}}
저장 경로: {{report_path}}

원래 요구사항:
{{request}}

기획 요약:
{{plan_summary}}

디자인 요약:
{{design_summary}}

개발 결과 요약:
{{dev_summary}}

코드 리뷰 요약:
{{review_summary}}

QA 결과:
{{qa_summary}}

추가 검증 요약:
{{validation_summary}}

변경 파일:
{{changed_files}}

보고서 기본 구조 (첫 줄의 주석은 반드시 포함하세요):
<!-- 도피스:Reporter -->
# 작업 보고서
## 요구사항
## 구현 결과
## QA 검증 결과
## 변경 파일
## 남은 리스크 및 다음 단계
"""
        case .sre:
            return """
당신은 도피스의 SRE입니다.
아래 구현 결과를 운영/배포/실행 안정성 관점에서 점검하세요.

프로젝트: {{project_name}}
경로: {{project_path}}

원래 요구사항:
{{request}}

개발 결과 요약:
{{dev_summary}}

QA 요약:
{{qa_summary}}

추가 검증 요약:
{{validation_summary}}

변경 파일:
{{changed_files}}

점검 양식:
- 배포/실행 리스크
- 환경 변수/설정 포인트
- 모니터링/알람 제안
- 롤백/수동 점검 포인트
- 최종 안정성 메모
"""
        }
    }

    public var automationContract: String {
        switch self {
        case .planner:
            return """
자동화 상태 계약:
- 응답 마지막 줄에 정확히 아래 한 줄을 남기세요.
PLANNER_STATUS: READY
"""
        case .designer:
            return """
자동화 상태 계약:
- 응답 마지막 줄에 정확히 아래 한 줄을 남기세요.
DESIGN_STATUS: READY
"""
        case .reviewer:
            return """
자동화 상태 계약:
- 응답 마지막 줄에는 아래 셋 중 하나만 정확히 한 줄로 남기세요.
REVIEW_STATUS: PASS
REVIEW_STATUS: FAIL
REVIEW_STATUS: BLOCKED
"""
        case .qa:
            return """
자동화 상태 계약:
- 응답 마지막 줄에는 아래 셋 중 하나만 정확히 한 줄로 남기세요.
QA_STATUS: PASS
QA_STATUS: FAIL
QA_STATUS: BLOCKED
"""
        case .reporter:
            return """
자동화 상태 계약:
- {{report_path}} 파일을 Markdown으로 작성하거나 갱신하세요.
- 응답 마지막 두 줄을 정확히 아래처럼 남기세요.
REPORT_STATUS: WRITTEN
REPORT_PATH: {{report_path}}
"""
        case .sre:
            return """
자동화 상태 계약:
- 응답 마지막 줄에 정확히 아래 한 줄을 남기세요.
SRE_STATUS: CHECKED
"""
        case .developerExecution, .developerRevision:
            return ""
        }
    }
}

public final class AutomationTemplateStore: ObservableObject {
    public static let shared = AutomationTemplateStore()

    private let saveKey = "doffice.automation.templates.v1"
    private let persistenceQueue = DispatchQueue(label: "doffice.automation-template-store", qos: .utility)
    private var saveWorkItem: DispatchWorkItem?
    @Published public private(set) var revision: Int = 0

    private var overrides: [String: String] = [:]

    private init() {
        load()
    }

    public func template(for kind: AutomationTemplateKind) -> String {
        overrides[kind.rawValue] ?? kind.defaultTemplate
    }

    public func binding(for kind: AutomationTemplateKind) -> Binding<String> {
        Binding(
            get: { self.template(for: kind) },
            set: { self.setTemplate($0, for: kind) }
        )
    }

    public func isCustomized(_ kind: AutomationTemplateKind) -> Bool {
        overrides[kind.rawValue] != nil
    }

    public func setTemplate(_ text: String, for kind: AutomationTemplateKind) {
        if text == kind.defaultTemplate {
            overrides.removeValue(forKey: kind.rawValue)
        } else {
            overrides[kind.rawValue] = text
        }
        revision &+= 1
        scheduleSave()
    }

    public func reset(_ kind: AutomationTemplateKind) {
        overrides.removeValue(forKey: kind.rawValue)
        revision &+= 1
        scheduleSave()
    }

    public func resetAll() {
        overrides.removeAll()
        revision &+= 1
        scheduleSave()
    }

    public func render(_ kind: AutomationTemplateKind, context: [String: String]) -> String {
        let body = renderText(template(for: kind), context: context)
        let contract = renderText(kind.automationContract, context: context)
        guard !contract.isEmpty else { return body }
        return body + "\n\n" + contract
    }

    private func renderText(_ template: String, context: [String: String]) -> String {
        var rendered = template
        for (key, value) in context {
            rendered = rendered.replacingOccurrences(of: "{{\(key)}}", with: value)
        }
        return rendered
    }

    private func scheduleSave(delay: TimeInterval = 0.25) {
        saveWorkItem?.cancel()
        let snapshot = overrides
        let key = saveKey
        let workItem = DispatchWorkItem {
            if snapshot.isEmpty {
                UserDefaults.standard.removeObject(forKey: key)
            } else if let data = try? JSONEncoder().encode(snapshot) {
                UserDefaults.standard.set(data, forKey: key)
            }
        }
        saveWorkItem = workItem
        persistenceQueue.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
            return
        }
        overrides = decoded
    }
}
