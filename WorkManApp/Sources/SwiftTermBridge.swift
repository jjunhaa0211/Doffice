import SwiftUI
import AppKit
import SwiftTerm

// ═══════════════════════════════════════════════════════
// MARK: - CLITerminalView (SwiftTerm 기반 100% 터미널)
// ═══════════════════════════════════════════════════════

struct CLITerminalView: NSViewRepresentable {
    let tab: TerminalTab
    var fontSize: CGFloat

    func makeNSView(context: Context) -> SwiftTermContainer {
        SwiftTermContainer(tab: tab, fontSize: fontSize)
    }

    func updateNSView(_ nsView: SwiftTermContainer, context: Context) {}
}

/// SwiftTerm의 LocalProcessTerminalView를 감싸는 컨테이너
class SwiftTermContainer: NSView, LocalProcessTerminalViewDelegate {
    weak var tab: TerminalTab?
    let terminalView: LocalProcessTerminalView

    init(tab: TerminalTab, fontSize: CGFloat) {
        self.tab = tab
        self.terminalView = LocalProcessTerminalView(frame: .zero)
        super.init(frame: .zero)

        terminalView.processDelegate = self
        terminalView.autoresizingMask = [.width, .height]

        // 터미널 스타일 설정
        terminalView.nativeBackgroundColor = NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        terminalView.nativeForegroundColor = NSColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)
        let monoFont = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        terminalView.font = monoFont
        // 한국어 IME 호환: Option을 Meta로 쓰지 않음
        terminalView.optionAsMetaKey = false

        addSubview(terminalView)

        // 셸 프로세스 시작
        let userShell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        let path = FileManager.default.fileExists(atPath: tab.projectPath) ? tab.projectPath : NSHomeDirectory()

        var env = ProcessInfo.processInfo.environment
        env["PATH"] = TerminalTab.buildFullPATH()
        env["TERM"] = "xterm-256color"
        // 시스템 로케일 유지 (한국어 IME 지원)
        if env["LANG"] == nil { env["LANG"] = "ko_KR.UTF-8" }
        env["HOME"] = NSHomeDirectory()

        let envArray = env.map { "\($0.key)=\($0.value)" }
        terminalView.startProcess(executable: userShell, args: ["-l"], environment: envArray, execName: "-zsh")

        // 포커스
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.window?.makeFirstResponder(self?.terminalView)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        terminalView.frame = bounds
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.window?.makeFirstResponder(self?.terminalView)
            }
        }
    }

    // MARK: - LocalProcessTerminalViewDelegate

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}

    func hostCurrentDirectoryUpdate(source: SwiftTerm.TerminalView, directory: String?) {}

    func processTerminated(source: SwiftTerm.TerminalView, exitCode: Int32?) {
        DispatchQueue.main.async { [weak self] in
            self?.tab?.isProcessing = false
            self?.tab?.claudeActivity = .idle
            self?.tab?.isRawMode = false
        }
    }
}
