//    MIT License
//
//    Copyright (c) 2019 Alexandre Frigon
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.
//

import UIKit
import QuickLook

class ThumbnailProvider: QLThumbnailProvider {
    static let repo: String = "https://swiftness.frigstudio.com/static/img/nes"

    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        //let checksum = request.fileURL.deletingPathExtension().lastPathComponent

//        do {
//            let file = request.fileURL
//            let data = try Data(contentsOf: request.fileURL)
//            let url = URL(string: "\(ThumbnailProvider.repo)/\(data.md5sum()).png")!
//
//            handler(QLThumbnailReply(imageFileURL: url), nil)
//        } catch {
//            return handler(nil, error)
//        }

        do {
            let file = request.fileURL
            let data = try Data(contentsOf: request.fileURL)
            let url = URL(string: "\(ThumbnailProvider.repo)/\(data.md5sum()).png")!

            let config = URLSessionConfiguration.background(withIdentifier: "com.frigstudio.swiftness.background-session-\(UUID().uuidString)")
            config.sharedContainerIdentifier = "group.swiftness.shared"

            let r = Request(url)
            r.urlSession = URLSession(configuration: config, delegate: DownloadDelegate(handler), delegateQueue: nil)
            r.send()
        } catch {
            return handler(nil, error)
        }
    }
}

class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    let handler: (QLThumbnailReply?, Error?) -> Void

    init(_ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        self.handler = handler
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        self.handler(QLThumbnailReply(imageFileURL: location), nil)
    }
}
