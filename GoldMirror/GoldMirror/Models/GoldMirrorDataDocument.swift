// MARK: - GoldMirrorDataDocument.swift
// Gold Mirror – Custom .gmdata file support.

import Foundation
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let goldMirrorData = UTType(exportedAs: "com.takuya.goldmirror.gmdata", conformingTo: .data)
}

struct GoldMirrorDataDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.goldMirrorData] }
    static var writableContentTypes: [UTType] { [.goldMirrorData] }

    var data: Data

    init(data: Data = Data()) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
