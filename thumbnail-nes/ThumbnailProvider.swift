//
//  ThumbnailProvider.swift
//  thumbnail-nes
//
//  Created by Alexandre Frigon on 2019-04-19.
//  Copyright © 2019 Frigstudio. All rights reserved.
//

import UIKit
import QuickLook

class ThumbnailProvider: QLThumbnailProvider {
    static let repo: String = "https://www.michaelfogleman.com/static/nes"

    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
//        let checksum = request.fileURL.deletingPathExtension().lastPathComponent

        do {
            let data = try Data(contentsOf: request.fileURL)
            let url = URL(string: "\(ThumbnailProvider.repo)/\(data.md5sum()).png")!

            handler(QLThumbnailReply(imageFileURL: url), nil)
        } catch {
            return handler(nil, error)
        }
    }
}
