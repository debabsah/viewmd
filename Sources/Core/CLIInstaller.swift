import Foundation
import AppKit

enum CLIInstaller {
    enum InstallError: LocalizedError {
        case shimMissing
        case noWritableLocation
        case adminCopyFailed(String)

        var errorDescription: String? {
            switch self {
            case .shimMissing: return "The bundled CLI shim is missing from the app."
            case .noWritableLocation: return "No writable install location found."
            case .adminCopyFailed(let why): return "Install with admin rights failed: \(why)"
            }
        }
    }

    static let candidateDirs = ["/opt/homebrew/bin", "/usr/local/bin"]

    static func bundledShimURL() -> URL? {
        Bundle.main.resourceURL?.appendingPathComponent("bin/viewmd")
    }

    /// Pure, testable copy: install `shim` as `<dir>/viewmd`, executable.
    @discardableResult
    static func install(into dir: URL, from shim: URL) throws -> URL {
        let fm = FileManager.default
        guard fm.fileExists(atPath: shim.path) else { throw InstallError.shimMissing }
        let target = dir.appendingPathComponent("viewmd")
        if fm.fileExists(atPath: target.path) {
            try fm.removeItem(at: target)
        }
        try fm.copyItem(at: shim, to: target)
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: target.path)
        return target
    }

    /// UI entry: try user-writable bin dirs, escalate via osascript if needed.
    static func installOnPath() throws -> URL {
        guard let shim = bundledShimURL() else { throw InstallError.shimMissing }
        let fm = FileManager.default
        for path in candidateDirs where fm.isWritableFile(atPath: path) {
            return try install(into: URL(fileURLWithPath: path), from: shim)
        }
        // No writable dir: copy to /usr/local/bin with admin privileges.
        let script = "do shell script \"mkdir -p /usr/local/bin && " +
            "cp '\(shim.path)' /usr/local/bin/viewmd && " +
            "chmod 755 /usr/local/bin/viewmd\" with administrator privileges"
        var errorInfo: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&errorInfo)
        if let errorInfo {
            throw InstallError.adminCopyFailed(String(describing: errorInfo[NSAppleScript.errorMessage]))
        }
        return URL(fileURLWithPath: "/usr/local/bin/viewmd")
    }
}
