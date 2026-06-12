import XCTest
@testable import viewmd

final class CLIInstallerTests: XCTestCase {

    func testInstallCopiesShimAndMakesExecutable() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("vmd-cli-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let shim = dir.appendingPathComponent("shim-src")
        try "#!/bin/sh\necho hi\n".write(to: shim, atomically: true, encoding: .utf8)

        let installed = try CLIInstaller.install(into: dir, from: shim)

        XCTAssertEqual(installed.lastPathComponent, "viewmd")
        let attrs = try FileManager.default.attributesOfItem(atPath: installed.path)
        let perms = (attrs[.posixPermissions] as! NSNumber).uint16Value
        XCTAssertEqual(perms & 0o111, 0o111, "shim must be executable")
    }

    func testInstallOverwritesExisting() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("vmd-cli-ow-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let shim = dir.appendingPathComponent("shim-src")
        try "#!/bin/sh\necho v2\n".write(to: shim, atomically: true, encoding: .utf8)
        try "old".write(to: dir.appendingPathComponent("viewmd"), atomically: true, encoding: .utf8)

        let installed = try CLIInstaller.install(into: dir, from: shim)
        XCTAssertTrue(try String(contentsOf: installed, encoding: .utf8).contains("echo v2"))
    }
}
