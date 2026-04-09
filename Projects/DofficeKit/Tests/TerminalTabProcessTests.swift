import XCTest
@testable import DofficeKit

final class TerminalTabProcessTests: XCTestCase {

    // MARK: - Cancel Processing

    func testCancelProcessingResetsState() {
        let tab = TerminalTab(projectName: "Test", projectPath: "/tmp", workerName: "Worker", workerColor: .blue)
        tab.isProcessing = true
        tab.claudeActivity = .thinking

        tab.cancelProcessing()

        XCTAssertFalse(tab.isProcessing)
        XCTAssertEqual(tab.claudeActivity, .idle)
        XCTAssertNil(tab.currentProcess)
    }

    func testCancelProcessingWhenNotProcessing() {
        let tab = TerminalTab(projectName: "Test", projectPath: "/tmp", workerName: "Worker", workerColor: .blue)
        tab.isProcessing = false
        tab.claudeActivity = .idle

        // Should not crash, should add status block
        tab.cancelProcessing()

        XCTAssertFalse(tab.isProcessing)
    }

    // MARK: - Force Stop

    func testForceStopCleansUpCompletely() {
        let tab = TerminalTab(projectName: "Test", projectPath: "/tmp", workerName: "Worker", workerColor: .blue)
        tab.isProcessing = true
        tab.isRunning = true
        tab.claudeActivity = .writing

        tab.forceStop()

        XCTAssertFalse(tab.isProcessing)
        XCTAssertFalse(tab.isRunning)
        XCTAssertEqual(tab.claudeActivity, .idle)
        XCTAssertNil(tab.currentProcess)
        XCTAssertNil(tab.currentOutPipe)
        XCTAssertNil(tab.currentErrPipe)
    }

    // MARK: - Block Trimming

    func testBlocksTrimmedAtLimit() {
        let tab = TerminalTab(projectName: "Test", projectPath: "/tmp", workerName: "Worker", workerColor: .blue)
        // maxRetainedBlocks is 420, add beyond that
        for i in 0..<450 {
            _ = tab.appendBlock(.text, content: "Block \(i)")
        }
        XCTAssertLessThanOrEqual(tab.blocks.count, TerminalTab.maxRetainedBlocks + 1)
    }

    // MARK: - Presentation Style

    func testSecretPresentationStyle() {
        let tab = TerminalTab(projectName: "Test", projectPath: "/tmp", workerName: "Worker", workerColor: .blue)
        tab.activeResponsePresentationStyle = .secret

        let block = tab.appendBlock(.thought, content: "secret thought")
        XCTAssertEqual(block.presentationStyle, .secret)
    }

    func testNormalPresentationStyleDefault() {
        let tab = TerminalTab(projectName: "Test", projectPath: "/tmp", workerName: "Worker", workerColor: .blue)
        let block = tab.appendBlock(.thought, content: "normal thought")
        XCTAssertEqual(block.presentationStyle, .normal)
    }

    func testClearPromptDecorations() {
        let tab = TerminalTab(projectName: "Test", projectPath: "/tmp", workerName: "Worker", workerColor: .blue)
        tab.activeResponsePresentationStyle = .secret
        tab.clearPromptDecorations()
        XCTAssertEqual(tab.activeResponsePresentationStyle, .normal)
    }

    func testUserPromptAlwaysNormalByDefault() {
        let tab = TerminalTab(projectName: "Test", projectPath: "/tmp", workerName: "Worker", workerColor: .blue)
        tab.activeResponsePresentationStyle = .secret
        // userPrompt uses the explicit style passed, not activeResponsePresentationStyle
        let block = tab.appendBlock(.userPrompt, content: "hello")
        XCTAssertEqual(block.presentationStyle, .normal)
    }

    // MARK: - Provider Switching

    func testSwitchProviderResetsState() {
        let tab = TerminalTab(projectName: "Test", projectPath: "/tmp", workerName: "Worker", workerColor: .blue)
        tab.isProcessing = true
        tab.sessionId = "test-session"
        tab.activeResponsePresentationStyle = .secret

        tab.switchProvider(to: .codex)

        XCTAssertFalse(tab.isProcessing)
        XCTAssertEqual(tab.claudeActivity, .idle)
        XCTAssertNil(tab.sessionId)
        XCTAssertEqual(tab.activeResponsePresentationStyle, .normal)
        XCTAssertEqual(tab.provider, .codex)
    }

    // MARK: - Tool Output Merge

    func testToolOutputBlocksMerge() {
        let tab = TerminalTab(projectName: "Test", projectPath: "/tmp", workerName: "Worker", workerColor: .blue)
        _ = tab.appendBlock(.toolOutput, content: "line 1")
        _ = tab.appendBlock(.toolOutput, content: "line 2")

        // Should merge into single block
        XCTAssertEqual(tab.blocks.count, 1)
        XCTAssertTrue(tab.blocks[0].content.contains("line 1"))
        XCTAssertTrue(tab.blocks[0].content.contains("line 2"))
    }

    func testToolErrorBlocksMerge() {
        let tab = TerminalTab(projectName: "Test", projectPath: "/tmp", workerName: "Worker", workerColor: .blue)
        _ = tab.appendBlock(.toolError, content: "err 1")
        _ = tab.appendBlock(.toolError, content: "err 2")

        XCTAssertEqual(tab.blocks.count, 1)
    }

    func testDifferentBlockTypesDontMerge() {
        let tab = TerminalTab(projectName: "Test", projectPath: "/tmp", workerName: "Worker", workerColor: .blue)
        _ = tab.appendBlock(.toolOutput, content: "output")
        _ = tab.appendBlock(.text, content: "text")

        XCTAssertEqual(tab.blocks.count, 2)
    }

    // MARK: - Enqueue Prompt

    func testEnqueuePromptAddsToQueue() {
        let tab = TerminalTab(projectName: "Test", projectPath: "/tmp", workerName: "Worker", workerColor: .blue)
        tab.enqueuePrompt("test prompt", presentationStyle: .secret)

        XCTAssertEqual(tab.queuedPromptRequests.count, 1)
        XCTAssertEqual(tab.queuedPromptRequests[0].prompt, "test prompt")
        XCTAssertEqual(tab.queuedPromptRequests[0].presentationStyle, .secret)
    }
}
