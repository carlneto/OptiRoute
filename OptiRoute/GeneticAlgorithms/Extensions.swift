import UIKit

extension Array {
    subscript(mod index: Index) -> Element {
        return self[modIndex(index)]
    }
    subscript(at index: Index) -> Element? {
        guard 0 ..< self.count ~= index else { return nil }
        return self[index]
    }
    func upTo(_ index: Index) -> [Element] {
        return Array(self.prefix(upTo: Swift.min(index, self.count)))
    }
    func modIndex(_ index: Index) -> Index {
        return ((index % count) + count) % count
    }
    mutating func swapIndexes(i: Int, j: Int) {
        swapAt(modIndex(i), modIndex(j))
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
    mutating func pick(at idx: Int) -> Element? {
        guard 0 ..< self.count ~= idx, self.count > 0 else { return nil }
        return self.remove(at: idx)
    }
    mutating func reverse(between index1: Int, and index2: Int) {
        if let ans = reversed(between: index1, and: index2) {
            self = ans
        }
    }
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
    func mixUp() -> [Element] {
        return sorted(by: { (_, _) -> Bool in
            return arc4random() < arc4random()
        })
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

final class Atomic<A> {
    private let q = DispatchQueue(label: "Atomic serial queue")
    private var v: A
    init(_ value: A) {
        self.v = value
    }
    var value: A {
        get { return q.sync { self.v } }
        set { self.mutate { $0 = newValue } }
    }
    func mutate(_ transform: (inout A) -> ()) {
        q.sync { transform(&self.v) }
    }
}
extension Atomic where A == Int {
    func increase() {
        mutate { $0 += 1 }
    }
    var increased: A {
        increase()
        return value
    }
    func decrease() {
        mutate { $0 -= 1 }
    }
    var decreased: A {
        decrease()
        return value
    }
}

final class BenchTimer {
    
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
    func str(reset: Bool, zeros: Int, leading: String = "", trailing: String = "") -> String {
        let ans = "\(leading)\(elapsed.zeros(zeros))\(trailing)"
        if reset { restart() }
        return ans
    }
}

extension Bool {
    static var arcRandom: Bool {
        return arc4random() < arc4random()
    }
    func xor(_ other: Bool) -> Bool {
        return self != other
    }
}

extension Double {
    func zeros(_ decimals: Int) -> String {
        return String(format: "%.\(decimals)f", self)
    }
}

extension Int {
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
    mutating func increase() {
        self += 1
    }
    mutating func increased() -> Int {
        self += 1
        return self
    }
    mutating func decrease() {
        self -= 1
    }
    mutating func decreased() -> Int {
        self -= 1
        return self
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
