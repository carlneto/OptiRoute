//
//  Extensions.swift
//  OptiRoute
//
//  Created by Carlos Neto on 08/04/2020.
//  Copyright © 2020 Carlos Neto. All rights reserved.
//
import UIKit

extension Array {
    subscript(mod index: Index) -> Element {
        return self[modIndex(index)]
    }
    func modIndex(_ index: Index) -> Index {
        return ((index % count) + count) % count
    }
    mutating func swapIndexes(i: Int, j: Int) {
        swapAt(modIndex(i), modIndex(j))
    }
    mutating func insert(item: Element, at destinationIndex: Int, before: Bool = true) {
        let toIdx = before ? modIndex(destinationIndex) : modIndex(destinationIndex + 1)
        self.insert(item, at: toIdx)
    }
    mutating func move(from sourceIndex: Int, to destinationIndex: Int, before: Bool = true) {
        let fromIdx = modIndex(sourceIndex)
        let toIdx = before ? modIndex(destinationIndex) : modIndex(destinationIndex + 1)
        guard fromIdx != toIdx else { return }
        guard abs(toIdx - fromIdx) != 1 else {
            self.swapAt(fromIdx, toIdx)
            return
        }
        self.insert(self.remove(at: fromIdx), at: fromIdx < toIdx ? toIdx - 1 : toIdx)
    }
    func moved(from sourceIndex: Int, to destinationIndex: Int, before: Bool = true) -> Array {
        var copy = self
        copy.move(from: sourceIndex, to: destinationIndex, before: before)
        return copy
    }
//    mutating func reverse(between index1: Int, and index2: Int) {
//        self = self.reversed(between: index1, and: index2)
//    }
    func reversed(between index1: Int, and index2: Int) -> Array? {
        guard index1 != index2, 0..<count ~= index1, 0..<count ~= index2 else { return nil }
        if index1 > index2 {
            let reversed = Array((self[(index1 + 1) ..< count] + self[0 ..< index2]).reversed())
            let arr = Array(self[index2 ... index1] + reversed)
            let cut = count - index2
            return Array(arr[cut ..< count] + arr[0 ..< cut])
        } else {
            let arr0 = self[0 ... index1]
            let arr1 = Array(self[(index1 + 1) ..< index2].reversed())
            let arr2 = self[index2 ..< count]
            return arr0 + arr1 + arr2
        }
    }
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

extension Array where Element: FloatingPoint {
    func sum() -> Element {
        return self.reduce(0, +)
    }
    func avg() -> Element {
        return self.sum() / Element(self.count)
    }
    func std() -> Element {
        let mean = self.avg()
        let v = self.reduce(0, { $0 + ($1 - mean) * ($1 - mean) })
        return sqrt(v / (Element(self.count) - 1))
    }
}

class BenchTimer {
    
    var startTime = CFAbsoluteTimeGetCurrent()
    
    var elapsed: CFAbsoluteTime {
        return CFAbsoluteTimeGetCurrent() - startTime
    }
    var milliseconds: CFAbsoluteTime {
        return 1000 * (CFAbsoluteTimeGetCurrent() - startTime)
    }
    func restart() {
        startTime = CFAbsoluteTimeGetCurrent()
    }
    func prt(restart: Bool = true, zeros: Int = 4, msg: String = "t:") {
        print("\(msg)\(elapsed.zeros(zeros))")
        if restart { startTime = CFAbsoluteTimeGetCurrent() }
    }
}

extension Bool {
    static var arcRandom: Bool {
        return arc4random() < arc4random()
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

extension Double {
    func zeros(_ decimals: Int) -> String {
        return String(format: "%.\(decimals)f", self)
    }
}

extension Int {
    subscript(`in` count: Int) -> Int {
        return ((self % count) + count) % count
    }
    var factDouble: Double {
        return (1...self).map(Double.init).reduce(1.0, *)
    }
    var factorial: Int? {
        guard factDouble < Double(Int.max) else { return nil }
        return Int(factDouble)
    }
    func sequence(to included: Int) -> (straight: [Int], inverted: [Int]) {
        var straight = [self], invertedInMiddle = [self]
        for i in (self + 1)...(included - 1) {
            straight.append(i)
            invertedInMiddle.append(self + included - i)
        }
        straight.append(included)
        invertedInMiddle.append(included)
        return (straight, invertedInMiddle)
    }
}

extension RangeReplaceableCollection {
    mutating func rotate(shift: Int) {
        let positions = ((shift % count) + count) % count
        let index = self.index(startIndex, offsetBy: positions, limitedBy: endIndex) ?? endIndex
        let slice = self[..<index]
        removeSubrange(..<index)
        insert(contentsOf: slice, at: endIndex)
    }
    func rotated(shift: Int) -> Self {
        var arr = self
        arr.rotate(shift: shift)
        return arr
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

func triangleHeight(left: Double, base: Double, right: Double) -> Double? {
    guard base < left + right else { return nil }
    guard left < base + right else { return nil }
    guard right < left + base else { return nil }
    let s = (left + base + right) / 2
    let a = (s * (s - left) * (s - base) * (s - right)).squareRoot()
    return 2 * a / base
}

func triangleOpposite(hypotenuse: Double, adjacent: Double) -> Double {
    return (pow(hypotenuse, 2) - pow(adjacent, 2)).squareRoot()
}
