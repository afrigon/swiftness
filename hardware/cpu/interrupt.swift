//
//  interrupt.swift
//  swiftness-ios
//
//  Created by Alexandre Frigon on 2019-09-10.
//  Copyright © 2019 Frigstudio. All rights reserved.
//

enum InterruptType: Word {
    case nmi = 0xFFFA       // Non-Maskable Interrupt triggered by ppu
    case reset = 0xFFFC     // Triggered on reset button press and initial boot
    case irq = 0xFFFE       // Maskable Interrupt triggered by a brk instruction or by memory mappers

    var address: Word {
        return self.rawValue
    }
}
