//
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

import Cocoa

fileprivate extension NSUserInterfaceItemIdentifier {
    static let paletteCell = NSUserInterfaceItemIdentifier("palette-item")
}

class PaletteCollectionViewItem: NSCollectionViewItem {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
    }

    func setColor(hex: UInt32) {
        self.view.layer?.backgroundColor = NSColor.black.cgColor
    }
}

class PaletteWindow: CenteredWindow, DebuggerDelegate, NSCollectionViewDataSource {
    weak private var debugger: Debugger!

    let collectionView = NSCollectionView()

    init(debugger: Debugger) {
        self.debugger = debugger

        super.init(width: CGFloat(480), height: CGFloat(480), styleMask: [.closable, .miniaturizable, .resizable, .titled])
        self.minSize = NSSize(width: CGFloat(360), height: CGFloat(240))
        self.title = "Swiftness - Palette"

        self.debugger.delegate = self
        self.collectionView.dataSource = self

        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 480 / 4, height: 480 / 4)
        flowLayout.sectionInset = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        self.collectionView.collectionViewLayout = flowLayout

        self.contentView?.addSubview(self.collectionView)
        self.contentView?.wantsLayer = true
        self.collectionView.layer?.backgroundColor = NSColor.black.cgColor
        self.collectionView.register(PaletteCollectionViewItem.self, forItemWithIdentifier: .paletteCell)
    }

    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        self.collectionView.frame = self.contentView?.bounds ?? .zero

    }

    private func updateValues() {

    }

    func debugger(debugger: Debugger, didDumpMemory memoryDump: MemoryDump, programCounter: Word) {
        self.updateValues()
    }

    func debugger(debugger: Debugger, didUpdate registers: RegisterSet) {}
    func toggleBreakpoints(_ sender: AnyObject) {}
    func run(_ sender: AnyObject) {}
    func step(_ sender: AnyObject) {}
    func stepLine(_ sender: AnyObject) {}
    func stepFrame(_ sender: AnyObject) {}
    func refresh(_ sender: AnyObject) {}

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 16
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let cell = collectionView.makeItem(withIdentifier: .paletteCell, for: indexPath) as? PaletteCollectionViewItem ?? PaletteCollectionViewItem()
        cell.setColor(hex: 0x123456)
        return cell
    }
}
