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
    static let debuggerBreakpointCell = NSUserInterfaceItemIdentifier("debugger-breakpoint-cell")

    static let debuggerColumn = NSUserInterfaceItemIdentifier("debugger-column")
    static let debuggerBreakpointColumn = NSUserInterfaceItemIdentifier("debugger-breakpoint-column")
}

fileprivate enum MemoryRegion: String {
    case zeroPage = "Zero Page"
    case ram = "RAM"
    case stack = "Stack"
    case io = "IO Registers"
    case expansion = "Expansion RAM"
    case save = "Save RAM"
    case romLow = "Lower Bank"
    case romHigh = "Higher Bank"
    case mirror = "Mirrors"
    case none = ""

    init(at address: Word) {
        switch address {
        case 0..<0x100: self = .zeroPage
        case 0x200..<0x800: self = .ram
        case 0x100..<0x200: self = .stack
        case 0x2000..<0x2008, 0x4000..<0x4020: self = .io
        case 0x4020..<0x6000: self = .expansion
        case 0x6000..<0x8000: self = .save
        case 0x8000..<0xC000: self = .romLow
        case 0xC000...0xFFFF: self = .romHigh
        case 0x800..<0x2000, 0x2008..<0x4000: self = .mirror
        default: self = .none
        }
    }

    static func getType(at address: Word) -> DebuggerTableCellView.IndicatorType {
        switch address {
        case 0x0, 0x200, 0x100, 0x2000, 0x2008, 0x4000, 0x4020, 0x6000, 0x8000, 0xC000: return .top
        case 0xFF, 0x7FF, 0x1FF, 0x2007, 0x401F, 0x5FFF, 0x7FFF, 0xFFFF, 0x1FFF, 0x3FFF: return .bottom
        default: return .middle
        }
    }
}

fileprivate class MenloTableCellView: NSView {
    let fontSize: CGFloat = 11.0

    let textField: NSTextField = {
        let textField = NSTextField()
        textField.drawsBackground = false
        textField.isBordered = false
        textField.isSelectable = false
        textField.isEditable = false
        textField.textColor = .gray

        return textField
    }()

    init() {
        super.init(frame: .zero)

        self.wantsLayer = true
        self.textField.font = NSFont(name: "menlo", size: fontSize)

        self.addSubview(self.textField)
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        let textFieldHeight = self.textField.attributedStringValue.size().height
        self.textField.frame = NSRect(x: 10,
                                      y: (self.bounds.height - textFieldHeight) / 2.0 + 1,
                                      width: self.bounds.width - 10,
                                      height: textFieldHeight + 2)
    }
}

fileprivate class DebuggerTableCellView: MenloTableCellView {
    let rightPadding: CGFloat = 10.0
    let indicatorWidth: CGFloat = 6.0
    let indicatorView = NSView()

    fileprivate enum IndicatorType { case top, middle, bottom }

    override init() {
        super.init()
        self.identifier = .debuggerCell
        self.addSubview(self.indicatorView)
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    func setSectionIndicator(to type: IndicatorType, for section: MemoryRegion) {
        let layer = CAShapeLayer()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))

        switch type {
        case .middle:
            path.addRect(CGRect(x: 0, y: 0, width: self.indicatorWidth, height: self.bounds.height))
        case .top:
            path.addRect(CGRect(x: 0, y: 0, width: self.indicatorWidth, height: self.bounds.height / 2))
            path.move(to: CGPoint(x: 0, y: self.bounds.height / 2))
            path.addCurve(to: CGPoint(x: self.indicatorWidth, y: self.bounds.height / 2),
                          control1: CGPoint(x: 0, y: self.bounds.height - 2),
                          control2: CGPoint(x: self.indicatorWidth, y: self.bounds.height - 2))
        case .bottom:
            path.addRect(CGRect(x: 0, y: self.bounds.height / 2, width: self.indicatorWidth, height: self.bounds.height / 2))
            path.move(to: CGPoint(x: 0, y: self.bounds.height / 2))
            path.addCurve(to: CGPoint(x: self.indicatorWidth, y: self.bounds.height / 2),
                          control1: CGPoint(x: 0, y: 2),
                          control2: CGPoint(x: self.indicatorWidth, y: 2))
        }

        layer.path = path
        layer.fillColor = DebuggerWindow.Theme.color(for: section).withAlphaComponent(0.7).cgColor
        // this effect has potential but is glitchy
        // self.indicatorView.layer = layer

        self.indicatorView.toolTip = section.rawValue
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        self.indicatorView.frame = NSRect(x: self.bounds.width - self.indicatorWidth - self.rightPadding,
                                          y: 0,
                                          width: self.indicatorWidth + self.rightPadding,
                                          height: self.bounds.height)
    }
}

fileprivate class DebuggerTableCellViewBreakpoint: MenloTableCellView {
    private let thingyWidth: CGFloat = 5.0

    private var _breakpoint: Breakpoint?
    var breakpoint: Breakpoint? {
        get { return self._breakpoint }
        set {
            self._breakpoint = newValue
            self.textField.textColor = newValue == nil ? .gray : .white
        }
    }

    private lazy var breakpointPath: NSBezierPath = {
        let path = NSBezierPath()
        path.move(to: .zero)
        path.line(to: NSPoint(x: self.bounds.width - self.thingyWidth, y: 0))
        path.line(to: NSPoint(x: self.bounds.width, y: self.bounds.height / 2))
        path.line(to: NSPoint(x: self.bounds.width - self.thingyWidth, y: self.bounds.height))
        path.line(to: NSPoint(x: 0, y: self.bounds.height))
        path.close()
        return path
    }()

    override init() {
        super.init()
        self.identifier = .debuggerBreakpointCell
        self.textField.alignment = .right
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        let textFieldHeight = self.textField.attributedStringValue.size().height
        self.textField.frame = NSRect(x: 0,
                                      y: (self.bounds.height - textFieldHeight) / 2.0 + 1,
                                      width: self.bounds.width - self.thingyWidth * 2,
                                      height: textFieldHeight)
    }

    override func draw(_ dirtyRect: NSRect) {
        if let breakpoint = self._breakpoint {
            DebuggerWindow.Theme.primary.withAlphaComponent(breakpoint.enabled ? 1.0 : 0.4).setFill()
            self.breakpointPath.fill()
        }

        super.draw(dirtyRect)
    }
}

class DebugView: NSView {
    fileprivate let debuggerToolbar: DebuggerToolbar!

    init(debugger: DebuggerWindow) {
        self.debuggerToolbar = DebuggerToolbar(debugger: debugger)
        super.init(frame: .zero)
        self.addSubview(self.debuggerToolbar)
        self.wantsLayer = true
        self.layer?.masksToBounds = false
    }

    required init?(coder decoder: NSCoder) {
        self.debuggerToolbar = nil
        super.init(coder: decoder)
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        self.debuggerToolbar.frame = NSRect(x: 0, y: self.bounds.height - 30, width: self.bounds.width, height: 30)
    }
}

class DebuggerSplitView: NSSplitView {
    override var dividerColor: NSColor {
        return DebuggerWindow.Theme.background
    }

    init() {
        super.init(frame: .zero)
        self.autosaveName = "debugger-splitview"
        self.dividerStyle = .thin
        self.isVertical = false
    }

    required init?(coder decoder: NSCoder) { super.init(coder: decoder) }
}

class DebuggerWindow: CenteredWindow, DebuggerDelegate, NSTableViewDelegate, NSTableViewDataSource, NSSplitViewDelegate {
    private let debugger: Debugger!
    private var currentLine: Int? = 0

    private let rowHeight: CGFloat = 18.0
    private let splitViewThreshold: CGFloat = 150.0

    private let splitView = DebuggerSplitView()
    private let scrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        return scrollView
    }()
    private let tableView: NSTableView = {
        let breakpointColumn = NSTableColumn(identifier: .debuggerBreakpointColumn)
        breakpointColumn.width = 60

        let column = NSTableColumn(identifier: .debuggerColumn)
        column.width = 1

        let tableView = NSTableView()
        tableView.headerView = nil
        tableView.intercellSpacing = .zero
        tableView.backgroundColor = Theme.background
        tableView.addTableColumn(breakpointColumn)
        tableView.addTableColumn(column)
        return tableView
    }()
    private var debugView: DebugView!
    private let variableView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        return scrollView
    }()

    init(debugger: Debugger) {
        self.debugger = debugger

        super.init(width: CGFloat(720), height: CGFloat(480), styleMask: [.closable, .miniaturizable, .resizable, .titled])
        self.minSize = NSSize(width: CGFloat(360), height: CGFloat(240))
        self.title = "Swiftness - Debugger"

        self.scrollView.documentView = self.tableView
        self.splitView.addSubview(self.scrollView)

        self.debugView = DebugView(debugger: self)
        self.debugView.addSubview(self.variableView)
        self.splitView.addSubview(self.debugView)

        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.splitView.delegate = self
        self.debugger.delegate = self



        self.contentView?.addSubview(self.splitView)

        self.splitView.adjustSubviews()

        self.tableView.target = self
        self.tableView.action = #selector(self.setBreakpoint(_:))
    }

    override func layoutIfNeeded() {
        guard let view = self.contentView else {
            self.splitView.frame = .zero
            return
        }

        self.splitView.frame = NSRect(x: 0,
                                      y: 0,
                                      width: view.bounds.width,
                                      height: view.bounds.height)
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.debugger.memoryDump.count
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return rowHeight
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let column = tableColumn else {
            return nil
        }

        switch column.identifier {
        case .debuggerColumn:
            var view = self.tableView.makeView(withIdentifier: .debuggerCell, owner: self) as? DebuggerTableCellView
            if view == nil { view = DebuggerTableCellView() }

            view!.layer?.backgroundColor = (self.currentLine ?? -1) == row
                ? Theme.breakpoint.cgColor
                : Theme.background.cgColor

            guard let info = self.debugger.memoryDump.getInfo(forLine: Word(row)) else {
                return view!
            }

            let string = NSMutableAttributedString(string: info.string)
            string.setColor(forString: info.raw, withColor: Theme.textRaw)
            string.setColor(forString: info.name, withColor: Theme.textKeywords)
            string.setColor(forString: info.textOperand, withColor: Theme.textNumbers)
            string.setColor(forStrings: [",x", ",y", ",a", " a"], withColor: Theme.textRegisters)
            string.setColor(forStrings: [",", "(", ")", "+", "-", "#"], withColor: Theme.textRegular)
            string.setColor(forStrings: ["indirect", "undefined"], withColor: Theme.textLowKey)
            view!.textField.attributedStringValue = string

            view!.setSectionIndicator(to: MemoryRegion.getType(at: info.addressPointer), for: MemoryRegion(at: info.addressPointer))

            return view
        case .debuggerBreakpointColumn:
            var view = self.tableView.makeView(withIdentifier: .debuggerBreakpointCell, owner: self) as? DebuggerTableCellViewBreakpoint
            if view == nil { view = DebuggerTableCellViewBreakpoint() }

            view!.layer?.backgroundColor = (self.currentLine ?? -1) == row
                ? Theme.breakpoint.cgColor
                : Theme.background.cgColor

            guard let info = self.debugger.memoryDump.getInfo(forLine: Word(row)) else {
                return view!
            }
            view!.textField.stringValue = info.addressPointer.hex()
            view!.breakpoint = self.debugger.breakpoints[info.addressPointer]

            return view
        default: return nil
        }
    }

    @objc func setBreakpoint(_ sender: AnyObject) {
        guard self.tableView.clickedColumn == 0 else {
            return
        }

        guard self.tableView.clickedRow != -1,
            let info = self.debugger.memoryDump.getInfo(forLine: Word(self.tableView.clickedRow)) else {
            return
        }

        if self.debugger.breakpoints.find(at: info.addressPointer) {
            //self.debugger.breakpoints.toggle(at: info.addressPointer)
            self.debugger.breakpoints.remove(at: info.addressPointer)
        } else {
            self.debugger.breakpoints.append(Breakpoint(address: info.addressPointer))
        }

        self.tableView.reloadData(forRowIndexes: [self.tableView.clickedRow], columnIndexes: [0])
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }

    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return true
    }

    func splitView(_ splitView: NSSplitView, shouldCollapseSubview subview: NSView, forDoubleClickOnDividerAt dividerIndex: Int) -> Bool {
        return true
    }

    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return proposedMinimumPosition + self.splitViewThreshold
    }

    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return proposedMaximumPosition - self.splitViewThreshold
    }

    func debugger(debugger: Debugger, didDumpMemory memoryDump: MemoryDump, programCounter: Word) {
        self.currentLine = Int(self.debugger.memoryDump.convert(addressToLine: programCounter) ?? 0)
        self.tableView.reloadData()
        self.tableView.scrollRowToVisible(self.currentLine!)
        self.updateToolbar()
    }

    func debugger(debugger: Debugger, didUpdate registers: RegisterSet) {
        var lines = IndexSet()
        if let oldLine = self.currentLine {
            lines.insert(oldLine)
        }
        self.currentLine = Int(self.debugger.memoryDump.convert(addressToLine: registers.pc) ?? 0)
        lines.insert(self.currentLine!)

        self.tableView.reloadData(forRowIndexes: lines, columnIndexes: [0, 1])
        self.tableView.scrollRowToVisible(self.currentLine!)

        // update regs in ui
    }

    @objc func run(_ sender: AnyObject) {
        var lines = IndexSet()
        if let oldLine = self.currentLine {
            lines.insert(oldLine)
        }
        self.currentLine = nil
        self.tableView.reloadData(forRowIndexes: lines, columnIndexes: [0, 1])
        self.debugger.running ? self.debugger.pause() : self.debugger.run()
        self.updateToolbar()
    }

    @objc func step(_ sender: AnyObject) {
        let cycles = self.debugger.step()
        self.debugView.debuggerToolbar.cycleLabel.stringValue = "Cycles: \(self.debugger.totalCycles) (+\(cycles))"
    }

    @objc func stepFrame(_ sender: AnyObject) {
        let cycles = self.debugger.stepFrame()
        self.debugView.debuggerToolbar.cycleLabel.stringValue = "Cycles: \(self.debugger.totalCycles) (+\(cycles))"
    }

    func updateToolbar() {
        self.debugView.debuggerToolbar.cycleLabel.stringValue = "Cycles: \(self.debugger.totalCycles)"
        self.debugView.debuggerToolbar.runButton.image = NSImage(named: self.debugger.running ? "pause" : "run")
        self.debugView.debuggerToolbar.runButton.toolTip = "\(self.debugger.running ? "Pause" : "Continue") program execution (F5)"

        if #available(OSX 10.12.2, *) {
            self.touchBar = self.makeTouchBar()
        }
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 96: self.run(self)
        case 101: self.stepFrame(self)
        case 109: self.step(self)
        default: print(event.keyCode)
        }
    }

    fileprivate class Theme {
        static let primary = NSColor(hex: 0xC47A31)
        static let background = NSColor(hex: 0x242428)
        static let toolbar = NSColor(hex: 0x343131)
        static let breakpoint = NSColor(hex: 0x3E5141)
        static let textKeywords = NSColor(hex: 0xFF6EA9)
        static let textRegisters = NSColor(hex: 0x91DB60)
        static let textNumbers = NSColor(hex: 0x9399FF)
        static let textRaw = NSColor(hex: 0xC47A31)
        static let textRegular = NSColor.white
        static let textLowKey = NSColor.gray

        static func color(for section: MemoryRegion) -> NSColor {
            switch section {
            case .zeroPage: return NSColor(hex: 0xBAE1FF)
            case .ram: return NSColor(hex: 0xbaffc9)
            case .stack: return NSColor(hex: 0xc4baff)
            case .io: return NSColor(hex: 0xb3fffe)
            case .expansion: return NSColor(hex: 0xcaffb3)
            case .save: return NSColor(hex: 0xf0b3ff)
            case .romLow: return NSColor(hex: 0xffdfba)
            case .romHigh: return NSColor(hex: 0xffb3ba)
            case .mirror: return NSColor(hex: 0xffffba)
            case .none: return .clear
            }
        }
    }
}

fileprivate class DebuggerToolbar: NSView {
    fileprivate class Button: NSImageView {
        init(image: NSImage?, target: AnyObject?, action: Selector?, toolTip: String? = nil) {
            super.init(frame: .zero)
            self.image = image
            self.target = target
            self.action = action
            self.toolTip = toolTip

            if #available(OSX 10.14, *) {
                self.contentTintColor = .white
            }
        }

        required init?(coder: NSCoder) { super.init(coder: coder) }

        override func mouseUp(with event: NSEvent) {
            self.sendAction(self.action, to: self.target)
        }
    }

    fileprivate class Label: NSTextField {
        init() {
            super.init(frame: .zero)
            self.backgroundColor = DebuggerWindow.Theme.toolbar
            self.textColor = .white
            self.isBezeled = false
            self.isEditable = false
            self.canDrawSubviewsIntoLayer = true
            self.alignment = .right
            self.stringValue = "Cycles: 0"

            self.font = NSFont.systemFont(ofSize: 13)
        }

        required init?(coder: NSCoder) { super.init(coder: coder) }
    }

    private let buttonSize: CGFloat = 20.0
    private let buttonPadding: CGFloat = 10.0

    private let buttonView = NSView()
    private let stepButton: DebuggerToolbar.Button!
    private let stepFrameButton: DebuggerToolbar.Button!
    let runButton: DebuggerToolbar.Button!
    let cycleLabel: DebuggerToolbar.Label!

    init(debugger: DebuggerWindow) {
        self.runButton = DebuggerToolbar.Button(image: NSImage(named: "run"),
                                                target: debugger,
                                                action: #selector(debugger.run(_:)),
                                                toolTip: "Continue program execution (F5)")
        self.stepButton = DebuggerToolbar.Button(image: NSImage(named: "step"),
                                                 target: debugger,
                                                 action: #selector(debugger.step(_:)),
                                                 toolTip: "Step into (F10)")
        self.stepFrameButton = DebuggerToolbar.Button(image: NSImage(named: "step"),
                                                      target: debugger,
                                                      action: #selector(debugger.stepFrame(_:)),
                                                      toolTip: "Step frame (F9)")
        self.cycleLabel = DebuggerToolbar.Label()
        super.init(frame: .zero)

        self.wantsLayer = true
        self.layer?.borderWidth = 1
        self.layer?.borderColor = .black
        self.layer?.backgroundColor = DebuggerWindow.Theme.toolbar.cgColor

        self.buttonView.addSubview(self.runButton)
        self.buttonView.addSubview(self.stepButton)
        self.buttonView.addSubview(self.stepFrameButton)
        self.addSubview(self.buttonView)
        self.addSubview(self.cycleLabel)
    }

    required init?(coder decoder: NSCoder) {
        self.stepButton = nil
        self.stepFrameButton = nil
        self.runButton = nil
        self.cycleLabel = nil
        super.init(coder: decoder)
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        self.buttonView.frame = NSRect(x: 0,
                                       y: 0,
                                       width: self.buttonPadding + (self.buttonPadding + self.buttonSize) * CGFloat(self.buttonView.subviews.count),
                                       height: self.bounds.height)
        let cycleLabelHeight = self.cycleLabel.attributedStringValue.size().height
        self.cycleLabel.frame = NSRect(x: self.buttonView.bounds.width,
                                       y: (self.bounds.height - cycleLabelHeight) / 2,
                                       width: self.bounds.width - self.buttonView.bounds.width - self.buttonPadding,
                                       height: cycleLabelHeight)

        for i in 0..<self.buttonView.subviews.count {
            self.buttonView.subviews[i].frame = NSRect(x: (self.buttonPadding + self.buttonSize) * CGFloat(i) + self.buttonPadding,
                                                       y: self.buttonPadding / 2,
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
            customViewItem.view = NSButton(image: NSImage(named: "step")!, target: self, action: #selector(self.step(_:)))
        case .runItem:
            customViewItem.view = NSButton(image: NSImage(named: self.debugger.running ? "pause" : "run")!, target: self, action: #selector(self.run(_:)))
        default: return nil
        }

        return customViewItem
    }
}
