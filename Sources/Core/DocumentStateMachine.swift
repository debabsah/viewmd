import Foundation

enum DocumentState: Equatable {
    case clean
    case edited
    case conflicted   // unsaved edits AND the file changed on disk
    case missing      // file deleted or moved; buffer retained
}

enum DocumentEvent: Equatable {
    case diskChanged
    case userEdited
    case saved
    case reloadedFromDisk
    case fileDisappeared
}

enum DocumentAction: Equatable {
    case reloadFromDisk
    case showConflictBanner
    case showMissingBanner
    case none
}

struct DocumentStateMachine {
    private(set) var state: DocumentState = .clean

    mutating func handle(_ event: DocumentEvent) -> DocumentAction {
        switch (state, event) {
        case (.clean, .diskChanged):
            return .reloadFromDisk
        case (.missing, .diskChanged):        // file came back, nothing to lose
            state = .clean
            return .reloadFromDisk
        case (_, .userEdited):
            if state == .clean || state == .edited { state = .edited }
            return .none
        case (.edited, .diskChanged):
            state = .conflicted
            return .showConflictBanner
        case (.conflicted, .diskChanged):
            return .none
        case (_, .saved):
            state = .clean
            return .none
        case (_, .reloadedFromDisk):
            state = .clean
            return .none
        case (_, .fileDisappeared):
            state = .missing
            return .showMissingBanner
        }
    }
}
