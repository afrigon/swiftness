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

    static let debuggerInfoCell = NSUserInterfaceItemIdentifier("debugger-info-cell")
    static let debuggerInfoColumn = NSUserInterfaceItemIdentifier("debugger-info-column")
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
}

fileprivate class MenloTableCellView: NSView {
    let fontSize: CGFloat

    let textField: NSTextField = {
        let textField = NSTextField()
        textField.drawsBackground = false
        textField.isBordered = false
        textField.isSelectable = false
        textField.isEditable = false

        return textField
    }()

    var _highlighted: Bool = false
    var highlighted: Bool {
        get { return self._highlighted }
        set { self._highlighted = newValue }
    }

    init(fontSize: CGFloat = 11) {
        self.fontSize = fontSize
        super.init(frame: .zero)

        self.wantsLayer = true
        self.textField.font = NSFont(name: "menlo", size: self.fontSize)

        self.addSubview(self.textField)
    }

    required init?(coder: NSCoder) {
        self.fontSize = 11
        super.init(coder: coder)
    }

    override func updateLayer() {
        self.layer?.backgroundColor = self._highlighted
            ? NSColor(named: .codeBackgroundHighlight)!.cgColor
            : NSColor.clear.cgColor
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        let textFieldHeight = self.textField.attributedStringValue.size().height
        self.textField.frame = NSRect(x: 5,
                                      y: (self.bounds.height - textFieldHeight) / 2.0 + 1,
                                      width: self.bounds.width - 5,
                                      height: textFieldHeight + 1)
    }
}

fileprivate class DebuggerTableCellView: MenloTableCellView {
    let rightPadding: CGFloat = 10.0
    let indicatorWidth: CGFloat = 6.0
    let indicatorView = NSView()

    fileprivate enum IndicatorType { case top, middle, bottom }

    init() {
        super.init()
        self.identifier = .debuggerCell
        self.addSubview(self.indicatorView)
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    func setSectionIndicator(for section: MemoryRegion) {
//        let layer = CAShapeLayer()
//        let path = CGMutablePath()
//        path.move(to: CGPoint(x: 0, y: 0))
//
//        switch type {
//        case .middle:
//            path.addRect(CGRect(x: 0, y: 0, width: self.indicatorWidth, height: self.bounds.height))
//        case .top:
//            path.addRect(CGRect(x: 0, y: 0, width: self.indicatorWidth, height: self.bounds.height / 2))
//            path.move(to: CGPoint(x: 0, y: self.bounds.height / 2))
//            path.addCurve(to: CGPoint(x: self.indicatorWidth, y: self.bounds.height / 2),
//                          control1: CGPoint(x: 0, y: self.bounds.height - 2),
//                          control2: CGPoint(x: self.indicatorWidth, y: self.bounds.height - 2))
//        case .bottom:
//            path.addRect(CGRect(x: 0, y: self.bounds.height / 2, width: self.indicatorWidth, height: self.bounds.height / 2))
//            path.move(to: CGPoint(x: 0, y: self.bounds.height / 2))
//            path.addCurve(to: CGPoint(x: self.indicatorWidth, y: self.bounds.height / 2),
//                          control1: CGPoint(x: 0, y: 2),
//                          control2: CGPoint(x: self.indicatorWidth, y: 2))
//        }

//        layer.path = path
//        layer.fillColor = DebuggerWindow.Theme.color(for: section).withAlphaComponent(0.7).cgColor
//        this effect has potential but is glitchy
//        self.indicatorView.layer = layer

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
    var breakpointColor: NSColor?

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

    init() {
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
        self.updateLayer()
        super.draw(dirtyRect)
        if let breakpoint = self._breakpoint {
            (self.breakpointColor ?? NSColor(named: .systemAccent)!).withAlphaComponent(breakpoint.enabled ? 1.0 : 0.4).setFill()
            self.breakpointPath.fill()
        }
    }
}

class DebugView: NSView {
    fileprivate let debuggerToolbar: DebuggerToolbar!
    fileprivate let variableView: NSOutlineView = {
        let outlineView = NSOutlineView()
        outlineView.autosaveExpandedItems = false

        let column = NSTableColumn()
        column.width = 1

        outlineView.headerView = nil
        outlineView.backgroundColor = NSColor(named: .background)!
        outlineView.addTableColumn(column)

        outlineView.indentationPerLevel = 10
        outlineView.floatsGroupRows = true
        outlineView.allowsColumnReordering = false
        outlineView.outlineTableColumn = column

        return outlineView
    }()
    private let variableScrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        return scrollView
    }()

    init(debugger: DebuggerWindow) {
        self.debuggerToolbar = DebuggerToolbar(debugger: debugger)
        super.init(frame: .zero)

        self.variableView.delegate = debugger
        self.variableView.dataSource = debugger

        self.variableScrollView.documentView = self.variableView

        self.addSubview(self.debuggerToolbar)
        self.addSubview(self.variableScrollView)
    }

    required init?(coder decoder: NSCoder) {
        self.debuggerToolbar = nil
        super.init(coder: decoder)
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        self.debuggerToolbar.frame = NSRect(x: 0, y: self.bounds.height - 30, width: self.bounds.width, height: 30)
        self.variableScrollView.frame = NSRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height - 30)
    }
}

class DebuggerSplitView: NSSplitView {
    init() {
        super.init(frame: .zero)
        self.autosaveName = "debugger-splitview"
        self.dividerStyle = .thin
        self.isVertical = false
    }

    override var dividerColor: NSColor { return .clear }

    required init?(coder decoder: NSCoder) { super.init(coder: decoder) }
}

class DebuggerWindow: CenteredWindow, DebuggerDelegate, NSTableViewDelegate, NSTableViewDataSource, NSSplitViewDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource {
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
        tableView.backgroundColor = NSColor(named: .background)!
        tableView.addTableColumn(breakpointColumn)
        tableView.addTableColumn(column)
        return tableView
    }()
    private var debugView: DebugView!

    init(debugger: Debugger) {
        self.debugger = debugger

        super.init(width: CGFloat(720), height: CGFloat(480), styleMask: [.closable, .miniaturizable, .resizable, .titled])
        self.minSize = NSSize(width: CGFloat(360), height: CGFloat(240))
        self.title = "Swiftness - Debugger"

        self.scrollView.documentView = self.tableView
        self.splitView.addSubview(self.scrollView)

        self.debugView = DebugView(debugger: self)
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
        super.layoutIfNeeded()
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

            view!.highlighted = (self.currentLine ?? -1) == row
            view!.updateLayer()

            guard let info = self.debugger.memoryDump.getInfo(forLine: Word(row)) else {
                return view!
            }

            let string = NSMutableAttributedString(string: info.string)
            string.setColor(forString: info.raw, withColor: NSColor(named: .codeRaw)!)
            string.setColor(forString: info.name, withColor: NSColor(named: .codeKeywords)!)
            string.setColor(forString: info.textOperand, withColor: NSColor(named: .codeNumbers)!)
            string.addAttributes(regex: "[axy]{1}$", [.foregroundColor : NSColor(named: .codeRegisters)!])
            string.setColor(forStrings: ["(", ")", ",", "+", "#"], withColor: NSColor(named: .text)!)
            string.addAttributes(regex: "[-]+", [.foregroundColor : NSColor(named: .text)!])
            string.addAttributes(regex: "indirect|undefined", [.foregroundColor : NSColor(named: .codeLowkey)!])
            view!.textField.attributedStringValue = string

            view!.setSectionIndicator(for: MemoryRegion(at: info.addressPointer))

            return view
        case .debuggerBreakpointColumn:
            var view = self.tableView.makeView(withIdentifier: .debuggerBreakpointCell, owner: self) as? DebuggerTableCellViewBreakpoint
            if view == nil { view = DebuggerTableCellViewBreakpoint() }

            view!.highlighted = (self.currentLine ?? -1) == row
            view!.updateLayer()

            guard let info = self.debugger.memoryDump.getInfo(forLine: Word(row)) else {
                return view!
            }
            view!.textField.stringValue = info.addressPointer.hex()
            view!.breakpoint = self.debugger.breakpoints[info.addressPointer]
            view!.breakpointColor = self.debugger.breakpoints.enabled
                ? NSColor(named: .systemAccent)
                : .gray

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

    private enum VariableType { case cpu, cpuFlag, stack, ppu, apu, rom }

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let item = item as? VariableType else {
            return 5
        }

        switch item {
        case .cpu: return 7
        case .cpuFlag: return 8
        case .stack: return 0x100 - Int(self.debugger.cpuRegisters.sp) - 1
        case .ppu: return 9
        case .apu: return 0
        case .rom: return 6
        }
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let item = item as? VariableType else {
            switch index {
            case 0: return VariableType.cpu
            case 1: return VariableType.stack
            case 2: return VariableType.ppu
            case 3: return VariableType.apu
            case 4: return VariableType.rom
            default: return ""
            }
        }

        switch item {
        case .cpu:
            switch index {
            case 0: return "Cycles = \(self.debugger.totalCycles)"
            case 1: return "A  (accumulator)      = $\(self.debugger.cpuRegisters.a.hex())"
            case 2: return "X                     = $\(self.debugger.cpuRegisters.x.hex())"
            case 3: return "Y                     = $\(self.debugger.cpuRegisters.y.hex())"
            case 4: return "SP (stack pointer)    = $\(self.debugger.cpuRegisters.sp.hex())"
            case 5: return "PC (program counter)  = $\(self.debugger.cpuRegisters.pc.hex())"
            case 6: return VariableType.cpuFlag
            default: return ""
            }
        case .cpuFlag:
            let value = (self.debugger.cpuRegisters.p.value >> Byte(7 - index)) & Byte(1)
            switch index {
            case 0: return "N (negative)    = \(value)"
            case 1: return "V (overflow)    = \(value)"
            case 2: return "  (always one)  = \(value)"
            case 3: return "B (breaks)      = \(value)"
            case 4: return "D (decimal)     = \(value)"
            case 5: return "I (interrupt)   = \(value)"
            case 6: return "Z (zero)        = \(value)"
            case 7: return "C (carry)       = \(value)"
            default: return ""
            }
        case .stack:
            let address: Word = 0x100 + self.debugger.cpuRegisters.sp + 1 + Word(index)
            return "$\(address.hex()) = $\(self.debugger.readMemory(at: address).hex())"
        case .ppu:
            switch index {
            case 0: return "Frame    = \("")"
            case 1: return "Scanline = \("")"
            case 2: return "Cycle    = \("")"
            case 3: return "$2000 (control register) = \("")"
            case 4: return "$2001 (mask register)    = \("")"
            case 5: return "$2002 (status register)  = \("")"
            case 6: return "$2003 (oam pointer)      = \("")"
            case 7: return "$2005 (scroll ?)         = \("")"
            case 8: return "$2006 (vram pointer)     = \("")"
            default: return ""
            }
        case .rom:
            switch index {
            case 0:
                guard let delegate = NSApplication.shared.delegate as? AppDelegate else { return "" }
                return "Filepath = \(delegate.options.filepath ?? "nil")"
            case 1: return "Program Banks = \(self.debugger.cartridge.programRom.count / 0x4000) -> \(self.debugger.cartridge.programRom.count / 1024)KB"
            case 2: return "Character Banks = \(self.debugger.cartridge.characterRom.count / 0x2000) -> \(self.debugger.cartridge.characterRom.count / 1024)KB"
            case 3: return "Battery = \(self.debugger.cartridge.battery)"
            case 4: return "Mirroring = \(String(describing: self.debugger.cartridge.mirroring))"
            case 5: return "Mapper = \(String(describing: self.debugger.cartridge.mapperType))"
            default: return ""
            }
        default: return ""
        }
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return item as? VariableType != nil
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        var view = outlineView.makeView(withIdentifier: .debuggerInfoCell, owner: self) as? MenloTableCellView
        if view == nil {
            view = MenloTableCellView()
        }

        view!.textField.textColor = NSColor(named: .text)!

        switch item {
        case let type as VariableType:
            let style: [NSAttributedString.Key: Any] = [.font: NSFont(name: "menlo bold", size: 11)!]
            switch type {
            case .cpu: view!.textField.attributedStringValue = NSAttributedString(string: "Core Processing Unit (cpu)", attributes: style)
            case .cpuFlag:
                let string = NSMutableAttributedString(string: "P  (processor status) = \(self.debugger.cpuRegisters.p.value.bin())")
                string.addAttributes(regex: "^.*=", [.font: NSFont(name: "menlo bold", size: 11)!])
                view!.textField.attributedStringValue = string
            case .stack: view!.textField.attributedStringValue = NSAttributedString(string: "Stack (\(Byte(0xFF) - self.debugger.cpuRegisters.sp))", attributes: style)
            case .ppu: view!.textField.attributedStringValue = NSAttributedString(string: "Picture Processing Unit (ppu)", attributes: style)
            case .apu: view!.textField.attributedStringValue = NSAttributedString(string: "Audio Processing Unit (apu)", attributes: style)
            case .rom: view!.textField.attributedStringValue = NSAttributedString(string: "Read Only Memory (rom)", attributes: style)
            }
        case let string as String:
            let string = NSMutableAttributedString(string: string)
            string.addAttributes(regex: "^.*=", [.font: NSFont(name: "menlo bold", size: 11)!])
            view!.textField.attributedStringValue = string
        case let string as NSAttributedString:
            view!.textField.attributedStringValue = string
        default: view!.textField.stringValue = ""
        }

        return view
    }

    func debugger(debugger: Debugger, didDumpMemory memoryDump: MemoryDump, programCounter: Word) {
        self.currentLine = Int(self.debugger.memoryDump.convert(addressToLine: programCounter) ?? 0)
        self.tableView.reloadData()
        self.tableView.scrollRowToVisible(self.currentLine!)
        self.updateToolbar()
        self.debugView.variableView.reloadData()
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

        self.debugView.variableView.reloadData()
    }

    @objc func toggleBreakpoints(_ sender: AnyObject) {
        self.debugger.breakpoints.enabled = !self.debugger.breakpoints.enabled
        self.debugView.debuggerToolbar.breakpointsButton.image = NSImage(named: "breakpoint-\(self.debugger.breakpoints.enabled ? "on" : "off")")
        self.debugView.debuggerToolbar.breakpointsButton.toolTip = "\(self.debugger.breakpoints.enabled ? "Disable" : "Enable") breakpoints"
        if #available(OSX 10.14, *) {
            self.debugView.debuggerToolbar.breakpointsButton.contentTintColor = self.debugger.breakpoints.enabled
                ? NSColor(named: .systemAccent)
                : NSColor(named: .icon)
        }

        let rowsWithBreaks = IndexSet(self.debugger.breakpoints.raw.map { (args) -> Int in
            return Int(self.debugger.memoryDump.convert(addressToLine: args.1.address) ?? 0)
        })
        self.tableView.reloadData(forRowIndexes: rowsWithBreaks, columnIndexes: [0])
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

    @objc func stepLine(_ sender: AnyObject) {
        let cycles = self.debugger.stepLine()
        self.debugView.debuggerToolbar.cycleLabel.stringValue = "Cycles: \(self.debugger.totalCycles) (+\(cycles))"
    }

    @objc func stepFrame(_ sender: AnyObject) {
        let cycles = self.debugger.stepFrame()
        self.debugView.debuggerToolbar.cycleLabel.stringValue = "Cycles: \(self.debugger.totalCycles) (+\(cycles))"
    }

    @objc func refresh(_ sender: AnyObject) {
        self.debugger.refresh()
    }

    func updateToolbar() {
        self.debugView.debuggerToolbar.cycleLabel.stringValue = "Cycles: \(self.debugger.totalCycles)"
        self.debugView.debuggerToolbar.runButton.image = NSImage(named: self.debugger.running ? "pause" : "resume")
        self.debugView.debuggerToolbar.runButton.toolTip = "\(self.debugger.running ? "Pause" : "Continue") program execution (F5)"

        if #available(OSX 10.12.2, *) {
            self.touchBar = self.makeTouchBar()
        }
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 96: self.run(self)         // F5
        case 97: self.refresh(self)     // F6
        case 98: self.stepLine(self)    // F7
        case 100: self.stepFrame(self)  // F8
        case 101: self.step(self)       // F9
        default: print(event.keyCode)
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
                self.contentTintColor = NSColor(named: .icon)
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
            self.textColor = NSColor(named: .text)!
            self.isBezeled = false
            self.isEditable = false
            self.canDrawSubviewsIntoLayer = true
            self.alignment = .right
            self.drawsBackground = false
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
    private let stepLineButton: DebuggerToolbar.Button!
    private let refreshButton: DebuggerToolbar.Button!
    let breakpointsButton: DebuggerToolbar.Button!
    let runButton: DebuggerToolbar.Button!
    let cycleLabel: DebuggerToolbar.Label!

    init(debugger: DebuggerWindow) {
        self.breakpointsButton = DebuggerToolbar.Button(image: NSImage(named: "breakpoint-on"),
                                                        target: debugger,
                                                        action: #selector(debugger.toggleBreakpoints(_:)),
                                                        toolTip: "Disable breakpoints")
        self.runButton = DebuggerToolbar.Button(image: NSImage(named: "resume"),
                                                target: debugger,
                                                action: #selector(debugger.run(_:)),
                                                toolTip: "Continue program execution (F5)")
        self.stepButton = DebuggerToolbar.Button(image: NSImage(named: "step-over"),
                                                 target: debugger,
                                                 action: #selector(debugger.step(_:)),
                                                 toolTip: "Step into (F9)")
        self.stepFrameButton = DebuggerToolbar.Button(image: NSImage(named: "step-over-frame"),
                                                      target: debugger,
                                                      action: #selector(debugger.stepFrame(_:)),
                                                      toolTip: "Step frame (F8)")
        self.stepLineButton = DebuggerToolbar.Button(image: NSImage(named: "step-over-line"),
                                                 target: debugger,
                                                 action: #selector(debugger.stepLine(_:)),
                                                 toolTip: "Step line (F7)")
        self.refreshButton = DebuggerToolbar.Button(image: NSImage(named: "memory"),
                                                      target: debugger,
                                                      action: #selector(debugger.refresh(_:)),
                                                      toolTip: "Refresh memory dump (F6)")
        self.cycleLabel = DebuggerToolbar.Label()
        super.init(frame: .zero)

        self.wantsLayer = true
        self.layer?.borderWidth = 1

        if #available(OSX 10.14, *) {
            self.breakpointsButton.contentTintColor = NSColor(named: .systemAccent)
        }

        self.buttonView.addSubview(self.breakpointsButton)
        self.buttonView.addSubview(self.runButton)
        self.buttonView.addSubview(self.stepButton)
        self.buttonView.addSubview(self.stepLineButton)
        self.buttonView.addSubview(self.stepFrameButton)
        self.buttonView.addSubview(self.refreshButton)
        self.addSubview(self.buttonView)
        self.addSubview(self.cycleLabel)
    }

    required init?(coder decoder: NSCoder) {
        self.stepButton = nil
        self.stepLineButton = nil
        self.stepFrameButton = nil
        self.refreshButton = nil
        self.breakpointsButton = nil
        self.runButton = nil
        self.cycleLabel = nil
        super.init(coder: decoder)
    }

    override func updateLayer() {
        self.layer?.borderColor = NSColor(named: .background)!.shiftBrightness(-0.1).cgColor
        self.layer?.backgroundColor = NSColor(named: .background)!.darkerColor.cgColor
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        self.buttonView.frame = NSRect(x: 0,
                                       y: 0,
                                       width: self.buttonPadding + (self.buttonPadding + self.buttonSize) * CGFloat(self.buttonView.subviews.count),
                                       height: self.bounds.height)
        let cycleLabelHeight = self.cycleLabel.attributedStringValue.size().height
        self.cycleLabel.frame = NSRect(x: self.buttonView.bounds.width,
                                       y: (self.bounds.height - cycleLabelHeight) / 2 + 2,
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
    static let runItem = NSTouchBarItem.Identifier("run-item")
    static let stepItem = NSTouchBarItem.Identifier("step-item")
    static let stepLineItem = NSTouchBarItem.Identifier("step-line-item")
    static let stepFrameItem = NSTouchBarItem.Identifier("step-frame-item")
    static let refreshItem = NSTouchBarItem.Identifier("refresh-item")
}

@available(OSX 10.12.2, *)
extension DebuggerWindow: NSTouchBarDelegate {
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = .debuggerTouchBar
        touchBar.defaultItemIdentifiers = [.runItem, .refreshItem, .stepItem, .stepFrameItem]
        return touchBar
    }

    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        let customViewItem = NSCustomTouchBarItem(identifier: identifier)

        switch identifier {
        case .runItem:
            customViewItem.view = NSButton(image: NSImage(named: self.debugger.running ? "pause" : "resume")!, target: self, action: #selector(self.run(_:)))
        case .stepItem:
            customViewItem.view = NSButton(image: NSImage(named: "step-over")!, target: self, action: #selector(self.step(_:)))
        case .stepLineItem:
            customViewItem.view = NSButton(image: NSImage(named: "step-over-line")!, target: self, action: #selector(self.stepLine(_:)))
        case .stepFrameItem:
            customViewItem.view = NSButton(image: NSImage(named: "step-over-frame")!, target: self, action: #selector(self.stepFrame(_:)))
        case .refreshItem:
            customViewItem.view = NSButton(image: NSImage(named: "memory")!, target: self, action: #selector(self.refresh(_:)))
        default: return nil
        }

        return customViewItem
    }
}
