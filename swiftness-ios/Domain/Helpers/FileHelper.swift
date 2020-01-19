//
//  FileHelper.swift
//  swiftness-osx
//
//  Created by Alexandre Frigon on 2019-04-19.
//  Copyright © 2019 Frigstudio. All rights reserved.
//

import Foundation
import SSZipArchive
import nes

extension FileManager {
    var documentURL: URL? {
        return try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    }

    var libraryURL: URL? {
        return try? FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    }

    var romsURL: URL? {
        guard let documentURL = self.documentURL else { return nil }
        return documentURL.appendingPathComponent("roms", isDirectory: true)
    }

    var saveURL: URL? {
        guard let documentURL = self.documentURL else { return nil }
        return documentURL.appendingPathComponent("save", isDirectory: true)
    }

    func pathFor(rom: String) -> URL? {
        guard let romsURL = self.romsURL else { return nil }
        return romsURL.appendingPathComponent("\(rom).nes")
    }
}

class FileHelper {
    static func initDocuments() throws {
        guard let romsURL = FileManager.default.romsURL else { throw NSError(domain: "", code: 1, userInfo: nil) }
        try FileManager.default.createDirectory(at: romsURL, withIntermediateDirectories: true, attributes: nil)

        guard let saveURL = FileManager.default.saveURL else { throw NSError(domain: "", code: 1, userInfo: nil) }
        try FileManager.default.createDirectory(at: saveURL, withIntermediateDirectories: true, attributes: nil)
    }

    static func openFromInbox(url: URL) throws -> Data {
        var filesURL: [URL]! = [url]
        if url.pathExtension.lowercased() == "zip" {
            let extractedURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)")
            try SSZipArchive.unzipFile(atPath: url.path, toDestination: extractedURL.path, overwrite: true, password: nil)
            filesURL = try? FileManager.default.contentsOfDirectory(at: extractedURL, includingPropertiesForKeys: nil)
            if filesURL == nil { filesURL = [] }
            filesURL.append(extractedURL)
        }


        for fileURL in filesURL {
            guard let magic = try? FileHandle(forReadingFrom: fileURL).readData(ofLength: 4) else { continue }
            guard NesFile.validateMagic(magic) else { continue }

            guard let data = try? Data(contentsOf: fileURL) else { continue }
            guard (try? FileHelper.copyToRoms(src: fileURL, filename: data.shasum())) != nil else { continue }
            return data
        }

        throw NSError(domain: "", code: 2, userInfo: nil)
    }

    static func open(url: URL) throws -> Data {
        if url.pathComponents.contains("Inbox") {
            return try FileHelper.openFromInbox(url: url)
        } else {
            return try Data(contentsOf: url)
        }
    }

    private static func copyToRoms(src: URL, filename: String) throws {
        guard let dst = FileManager.default.pathFor(rom: filename) else { throw NSError(domain: "", code: 3, userInfo: nil) }
        try FileManager.default.moveItem(at: src, to: dst)
    }
}
