//
//  integer.swift
//  swift-nes
//
//  Created by Alexandre Frigon on 2018-10-21.
//  Copyright © 2018 Frigstudio. All rights reserved.
//

extension Array {
    subscript(index: UInt8) -> Element {
        get {
            return self[Int(index)]
        }
        set(newValue) {
            self[Int(index)] = newValue
        }
    }
    
    subscript(index: UInt16) -> Element {
        get {
            return self[Int(index)]
        }
        set(newValue) {
            self[Int(index)] = newValue
        }
    }
    
    subscript(index: UInt32) -> Element {
        get {
            return self[Int(index)]
        }
        set(newValue) {
            self[Int(index)] = newValue
        }
    }
    
    subscript(index: UInt64) -> Element {
        get {
            return self[Int(index)]
        }
        set(newValue) {
            self[Int(index)] = newValue
        }
    }
}


extension Int {
    static postfix func ++ (value: inout Int) {
        value += 1
    }
    
    static postfix func -- (value: inout Int) {
        value -= 1
    }
}

extension Int8 {
    static postfix func ++ (value: inout Int8) {
        value += 1
    }
    
    static postfix func -- (value: inout Int8) {
        value -= 1
    }
}

extension Int16 {
    static postfix func ++ (value: inout Int16) {
        value += 1
    }
    
    static postfix func -- (value: inout Int16) {
        value -= 1
    }
}

extension Int32 {
    static postfix func ++ (value: inout Int32) {
        value += 1
    }
    
    static postfix func -- (value: inout Int32) {
        value -= 1
    }
}

extension Int64 {
    static postfix func ++ (value: inout Int64) {
        value += 1
    }
    
    static postfix func -- (value: inout Int64) {
        value -= 1
    }
}

extension UInt {
    static postfix func ++ (value: inout UInt) {
        value += 1
    }
    
    static postfix func -- (value: inout UInt) {
        value -= 1
    }
}

extension UInt8 {
    static postfix func ++ (value: inout UInt8) {
        value += 1
    }
    
    static postfix func -- (value: inout UInt8) {
        value -= 1
    }
}

extension UInt16 {
    static postfix func ++ (value: inout UInt16) {
        value += 1
    }
    
    static postfix func -- (value: inout UInt16) {
        value -= 1
    }
}

extension UInt32 {
    static postfix func ++ (value: inout UInt32) {
        value += 1
    }
    
    static postfix func -- (value: inout UInt32) {
        value -= 1
    }
}

extension UInt64 {
    static postfix func ++ (value: inout UInt64) {
        value += 1
    }
    
    static postfix func -- (value: inout UInt64) {
        value -= 1
    }
}
