//
//    MIT License
//
//    Copyright (c) 2018 Alexandre Frigon
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
    static let debuggerCell = NSUserInterfaceItemIdentifier("debugger-cell")
    static let debuggerColumn = NSUserInterfaceItemIdentifier("debugger-column")
}

class DebuggerTableCellView: NSView {
    let textField: NSTextField = {
        let textField = NSTextField()
        textField.drawsBackground = true
        textField.isBordered = false
        textField.isSelectable = false
        textField.isEditable = false
        textField.focusRingType = .none
        textField.textColor = .white
        textField.font = NSFont(name: "menlo", size: 12)

        return textField
    }()

    init() {
        super.init(frame: .zero)
        self.identifier = .debuggerCell
        self.focusRingType = .none
        self.addSubview(self.textField)
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        self.textField.frame = self.frame
    }
}

class DebuggerWindow: CenteredWindow, DebuggerDelegate, NSTableViewDelegate, NSTableViewDataSource {
    private let debugger: Debugger!
    private var dump: [String]?
    private var pc: Int = 0

    private let toolbarHeight: CGFloat = 30.0
    private let rowHeight: CGFloat = 20.0
    private let scrollView = NSScrollView()
    private let tableView: NSTableView = {
        let column = NSTableColumn(identifier: .debuggerColumn)
        column.width = 1

        let tableView = NSTableView()
        tableView.headerView = nil
        tableView.focusRingType = .none
        tableView.addTableColumn(column)
        return tableView
    }()
    private var debuggerToolbar: DebuggerToolbar!

    init(debugger: Debugger) {
        self.debugger = debugger

        super.init(width: CGFloat(1080), height: CGFloat(720), styleMask: [.closable, .miniaturizable, .resizable, .titled])
        self.title = "Swiftness - Debugger"

        self.tableView.backgroundColor = .dark

        self.scrollView.documentView = self.tableView
        self.scrollView.hasVerticalScroller = true
        self.contentView?.addSubview(scrollView)

        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.debugger.delegate = self

        self.debuggerToolbar = DebuggerToolbar(debugger: self)
        self.contentView?.addSubview(self.debuggerToolbar)
    }

    override func layoutIfNeeded() {
        guard let view = self.contentView else {
            self.scrollView.frame = .zero
            self.debuggerToolbar.frame = .zero
            return
        }

        self.scrollView.frame = NSRect(x: 0,
                                       y: self.toolbarHeight,
                                       width: view.bounds.width,
                                       height: view.bounds.height - self.toolbarHeight)
        self.debuggerToolbar.frame = NSRect(x: 0,
                                            y: 0,
                                            width: view.bounds.width,
                                            height: self.toolbarHeight)
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.dump?.count ?? 0
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return rowHeight
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var view = self.tableView.makeView(withIdentifier: .debuggerCell, owner: self) as? DebuggerTableCellView

        if view == nil {
            view = DebuggerTableCellView()
        }

        view!.textField.backgroundColor = self.pc == row ? .primary : .dark
        view!.textField.stringValue = self.dump?[row] ?? ""

        return view
    }

    func debugger(debugger: Debugger, didDumpMemory dump: [String], pc: Int) {
        self.pc = pc
        self.dump = dump

        self.tableView.reloadData()
        self.tableView.scrollRowToVisible(self.pc)
    }

    func debugger(debugger: Debugger, didUpdate pc: Int) {
        let oldpc = self.pc
        self.pc = pc

        self.tableView.reloadData(forRowIndexes: [oldpc, self.pc], columnIndexes: [0])
        self.tableView.scrollRowToVisible(self.pc)
    }

    @objc func step(_ sender: AnyObject) {
        self.debugger.step()
    }

    @objc func run(_ sender: AnyObject) {
        self.debugger.run()
    }

    @objc func pause(_ sender: AnyObject) {
        self.debugger.pause()
    }
}

fileprivate class DebuggerToolbar: NSView {
    fileprivate class Button: NSControl {
        var image: NSImage? = nil

        init(image: NSImage?, target: AnyObject?, action: Selector?, keyEquivalent: String = "") {
            super.init(frame: .zero)
            self.image = image
            self.target = target
            self.action = action

            self.isEnabled = true
            self.appearance = NSAppearance(named: .aqua)
        }

        required init?(coder: NSCoder) { super.init(coder: coder) }

        override func draw(_ dirtyRect: NSRect) {
            self.image?.draw(in: NSRect(x: 0, y: 0, width: 30, height: 30))
        }
    }

    private let buttonSize: CGFloat = 30.0

    private let stepButton: DebuggerToolbar.Button!
    private let runButton: DebuggerToolbar.Button!

    init(debugger: DebuggerWindow) {
        self.stepButton = DebuggerToolbar.Button(image: NSImage(named: "step"),
                                                 target: debugger,
                                                 action: #selector(debugger.step(_:)),
                                                 keyEquivalent: "a")
        self.runButton = DebuggerToolbar.Button(image: NSImage(named: "run"),
                                                target: debugger,
                                                action: #selector(debugger.run(_:)),
                                                keyEquivalent: "F5")
        super.init(frame: .zero)

        self.wantsLayer = true
        self.layer?.borderWidth = 1
        self.layer?.borderColor = .black
        self.layer?.backgroundColor = NSColor.dark.cgColor

        self.addSubview(self.runButton)
        self.addSubview(self.stepButton)
    }

    required init?(coder decoder: NSCoder) {
        self.stepButton = nil
        self.runButton = nil
        super.init(coder: decoder)
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        for i in 0..<self.subviews.count {
            self.subviews[i].frame = NSRect(x: self.buttonSize * CGFloat(i),
                                            y: 0,
                                            width: self.buttonSize,
                                            height: self.buttonSize)
        }
    }
}

@available(OSX 10.12.2, *)
fileprivate extension NSTouchBar.CustomizationIdentifier {
    static let debuggerTouchBar = NSTouchBar.CustomizationIdentifier("debugger-touchbar")
}

@available(OSX 10.12.2, *)
fileprivate extension NSTouchBarItem.Identifier {
    static let stepItem = NSTouchBarItem.Identifier("step-item")
    static let runItem = NSTouchBarItem.Identifier("run-item")
}

@available(OSX 10.12.2, *)
extension DebuggerWindow: NSTouchBarDelegate {
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = .debuggerTouchBar
        touchBar.defaultItemIdentifiers = [.runItem, .stepItem]
        return touchBar
    }

    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        let customViewItem = NSCustomTouchBarItem(identifier: identifier)

        switch identifier {
        case .stepItem:
            let button = NSButton(image: NSImage(named: "step")!, target: self, action: #selector(self.step(_:)))
            customViewItem.view = button
        case .runItem:
            if self.debugger.running {
                let button = NSButton(image: NSImage(named: "pause")!, target: self, action: #selector(self.pause(_:)))
                customViewItem.view = button
            } else {
                let button = NSButton(image: NSImage(named: "run")!, target: self, action: #selector(self.run(_:)))
                customViewItem.view = button
            }
        default: return nil
        }

        return customViewItem
    }
}
