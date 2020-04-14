//
//  Extensions.swift
//  OptiRoute
//
//  Created by Carlos Neto on 08/04/2020.
//  Copyright © 2020 Carlos Neto. All rights reserved.
//
import UIKit

public class BenchTimer {
    
    var startTime = CFAbsoluteTimeGetCurrent()
    
    public var elapsed: CFAbsoluteTime {
        return CFAbsoluteTimeGetCurrent() - startTime
    }
    
    public func restart() {
        startTime = CFAbsoluteTimeGetCurrent()
    }
}

extension String {
    func keyForSaving(_ val: Any, sync: Bool = true) {
        func perform(_ key: String) {
            guard !key.isEmpty else { return }
            let userDefaults = UserDefaults.standard
            userDefaults.set(val, forKey: key)
            userDefaults.synchronize()
        }
        let key = self
        sync ? perform(key) : DispatchQueue.global(qos: .background).async { perform(key) }
    }
    func keyForRead() -> [String] {
        guard !isEmpty else { return [String]() }
        return UserDefaults.standard.stringArray(forKey: self) ?? [String]()
    }
    func keyToRemoveObject(sync: Bool) {
        func perform(_ key: String) {
            guard !key.isEmpty else { return }
            let userDefaults = UserDefaults.standard
            userDefaults.removeObject(forKey: key)
            userDefaults.synchronize()
        }
        let key = self
        sync ? perform(key) : DispatchQueue.global(qos: .background).async { perform(key) }
    }
    func widthFrom(height: CGFloat, usingFont: UIFont) -> CGFloat {
        let label =  UILabel(frame: CGRect(x: 0, y: 0, width: .greatestFiniteMagnitude, height: height))
        label.numberOfLines = 0
        label.text = self
        label.font = usingFont
        label.sizeToFit()
        return label.frame.width
    }
}

extension RangeReplaceableCollection {
    mutating func rotate(positions: Int) {
        let index = self.index(startIndex, offsetBy: positions, limitedBy: endIndex) ?? endIndex
        let slice = self[..<index]
        removeSubrange(..<index)
        insert(contentsOf: slice, at: endIndex)
    }
}

public extension Int {
    var factDouble: Double {
        return (1...self).map(Double.init).reduce(1.0, *)
    }
    var factorial: Int? {
        guard factDouble < Double(Int.max) else { return nil }
        return Int(factDouble)
    }
}

extension Double {
    func zeros(_ decimals: Int) -> String {
        return String(format: "%.\(decimals)f", self)
    }
}

extension Collection where Element: Numeric {
    /// Returns the total sum of all elements in the array
    var total: Element { reduce(0, +) }
}

extension Collection where Element: BinaryInteger {
    /// Returns the average of all elements in the array
    var average: Double { isEmpty ? 0 : Double(total) / Double(count) }
}

extension Collection where Element: BinaryFloatingPoint {
    /// Returns the average of all elements in the array
    var average: Element { isEmpty ? 0 : total / Element(count) }
}

extension Array {
    func shuffle() -> [Element] {
        return sorted(by: { (_, _) -> Bool in
            return arc4random() < arc4random()
        })
    }
    var splitted: (left: [Element], right: [Element]) {
        let ct = self.count
        let half = ct / 2
        let leftSplit = self[0 ..< half]
        let rightSplit = self[half ..< ct]
        return (left: Array(leftSplit), right: Array(rightSplit))
    }
    func chunk(min size: Int) -> [[Element]] {
        var arr = chunk(max: size)
        if let last = arr.last, last.count < size {
            arr[0] += last
            arr.removeLast()
        }
        return arr
    }
    func chunk(max size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

