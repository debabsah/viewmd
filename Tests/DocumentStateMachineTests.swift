import XCTest
@testable import viewmd

final class DocumentStateMachineTests: XCTestCase {

    func testCleanDiskChangeAutoReloads() {
        var sm = DocumentStateMachine()
        XCTAssertEqual(sm.handle(.diskChanged), .reloadFromDisk)
        XCTAssertEqual(sm.state, .clean)
    }

    func testEditingMarksEdited() {
        var sm = DocumentStateMachine()
        XCTAssertEqual(sm.handle(.userEdited), .none)
        XCTAssertEqual(sm.state, .edited)
    }

    func testEditedDiskChangeConflicts() {
        var sm = DocumentStateMachine()
        _ = sm.handle(.userEdited)
        XCTAssertEqual(sm.handle(.diskChanged), .showConflictBanner)
        XCTAssertEqual(sm.state, .conflicted)
    }

    func testConflictedDiskChangeStaysConflicted() {
        var sm = DocumentStateMachine()
        _ = sm.handle(.userEdited)
        _ = sm.handle(.diskChanged)
        XCTAssertEqual(sm.handle(.diskChanged), .none)
        XCTAssertEqual(sm.state, .conflicted)
    }

    func testSaveResolvesEditedAndConflicted() {
        var sm = DocumentStateMachine()
        _ = sm.handle(.userEdited)
        XCTAssertEqual(sm.handle(.saved), .none)
        XCTAssertEqual(sm.state, .clean)

        _ = sm.handle(.userEdited)
        _ = sm.handle(.diskChanged)
        _ = sm.handle(.saved)                  // user chose "Keep mine"
        XCTAssertEqual(sm.state, .clean)
    }

    func testReloadResolvesConflict() {
        var sm = DocumentStateMachine()
        _ = sm.handle(.userEdited)
        _ = sm.handle(.diskChanged)
        XCTAssertEqual(sm.handle(.reloadedFromDisk), .none)   // user chose "Reload"
        XCTAssertEqual(sm.state, .clean)
    }

    func testFileDisappearedFromAnyStateShowsMissingBanner() {
        for prime in [[], [DocumentEvent.userEdited], [.userEdited, .diskChanged]] {
            var sm = DocumentStateMachine()
            prime.forEach { _ = sm.handle($0) }
            XCTAssertEqual(sm.handle(.fileDisappeared), .showMissingBanner)
            XCTAssertEqual(sm.state, .missing)
        }
    }

    func testMissingResolvedBySave() {
        var sm = DocumentStateMachine()
        _ = sm.handle(.fileDisappeared)
        _ = sm.handle(.saved)                  // Save As / re-save restores
        XCTAssertEqual(sm.state, .clean)
    }

    func testMissingFileReappearingReloadsWhenNoEdits() {
        var sm = DocumentStateMachine()
        _ = sm.handle(.fileDisappeared)
        XCTAssertEqual(sm.handle(.diskChanged), .reloadFromDisk)
        XCTAssertEqual(sm.state, .clean)
    }
}
