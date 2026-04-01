import XCTest
@testable import DofficeKit

final class TerminalTabBlockTests: XCTestCase {

    func testAppendBlockReturnsBlock() {
        let tab = TerminalTab(projectName: "Test", projectPath: "/tmp", workerName: "Worker", workerColor: .blue)
        let block = tab.appendBlock(.text, content: "Hello")
        XCTAssertEqual(block.content, "Hello")
        XCTAssertEqual(tab.blocks.count, 1)
    }

    func testAppendMultipleBlocks() {
        let tab = TerminalTab(projectName: "Test", projectPath: "/tmp", workerName: "Worker", workerColor: .blue)
        _ = tab.appendBlock(.text, content: "First")
        _ = tab.appendBlock(.thought, content: "Thinking...")
        _ = tab.appendBlock(.text, content: "Second")
        XCTAssertEqual(tab.blocks.count, 3)
    }

    func testAppendUserPromptBlock() {
        let tab = TerminalTab(projectName: "Test", projectPath: "/tmp", workerName: "Worker", workerColor: .blue)
        _ = tab.appendBlock(.userPrompt, content: "Fix the bug")
        XCTAssertEqual(tab.blocks.count, 1)
        if case .userPrompt = tab.blocks[0].blockType {
            // OK
        } else {
            XCTFail("Expected userPrompt block type")
        }
    }

    func testIsAutomationTabDefault() {
        let tab = TerminalTab(projectName: "Test", projectPath: "/tmp", workerName: "Worker", workerColor: .blue)
        XCTAssertFalse(tab.isAutomationTab)
    }

    func testIsAutomationTabWhenAutomationSource() {
        let tab = TerminalTab(projectName: "Test", projectPath: "/tmp", workerName: "Worker", workerColor: .blue)
        tab.automationSourceTabId = "parent-tab-id"
        XCTAssertTrue(tab.isAutomationTab)
    }

    func testProviderProperty() {
        let tab = TerminalTab(projectName: "Test", projectPath: "/tmp", workerName: "Worker", workerColor: .blue)
        tab.selectedModel = .sonnet
        XCTAssertEqual(tab.provider, .claude)
        tab.selectedModel = .gpt54
        XCTAssertEqual(tab.provider, .codex)
        tab.selectedModel = .gemini25Pro
        XCTAssertEqual(tab.provider, .gemini)
    }

    // MARK: - toolEnd → isComplete Tests

    func testToolEndMarksToolUseComplete() {
        let tab = TerminalTab(projectName: "Test", projectPath: "/tmp", workerName: "Worker", workerColor: .blue)
        _ = tab.appendBlock(.toolUse(name: "Grep", input: "pattern"), content: "searching...")
        XCTAssertFalse(tab.blocks[0].isComplete, "toolUse should start as not complete")

        _ = tab.appendBlock(.toolEnd(success: true))
        XCTAssertTrue(tab.blocks[0].isComplete, "toolUse should be marked complete after toolEnd")
    }

    func testToolEndFailureStillMarksComplete() {
        let tab = TerminalTab(projectName: "Test", projectPath: "/tmp", workerName: "Worker", workerColor: .blue)
        _ = tab.appendBlock(.toolUse(name: "Bash", input: "ls"), content: "running...")
        _ = tab.appendBlock(.toolEnd(success: false))
        XCTAssertTrue(tab.blocks[0].isComplete, "toolUse should be complete even on failure")
    }

    func testMultipleToolUsesOnlyLastMarkedComplete() {
        let tab = TerminalTab(projectName: "Test", projectPath: "/tmp", workerName: "Worker", workerColor: .blue)
        _ = tab.appendBlock(.toolUse(name: "Read", input: "file1"), content: "reading...")
        _ = tab.appendBlock(.toolEnd(success: true))
        _ = tab.appendBlock(.toolUse(name: "Edit", input: "file2"), content: "editing...")

        XCTAssertTrue(tab.blocks[0].isComplete, "First toolUse should be complete")
        // blocks[1] is toolEnd
        XCTAssertFalse(tab.blocks[2].isComplete, "Second toolUse should not be complete yet")

        _ = tab.appendBlock(.toolEnd(success: true))
        XCTAssertTrue(tab.blocks[2].isComplete, "Second toolUse should now be complete")
    }

    func testTokenLimitDefaultZero() {
        let tab = TerminalTab(projectName: "Test", projectPath: "/tmp", workerName: "Worker", workerColor: .blue)
        XCTAssertEqual(tab.tokenLimit, 0, "Default tokenLimit should be 0 (unlimited)")
    }
}
