import UIKit

struct Organ: Equatable, Hashable, Comparable {
    
    private static var edges = [[String] : Double]()
    fileprivate static var uniqueBody = [String : Organ]()
    
    private (set) var name: String
    
    let content: Any
    
    private init(name: String, core content: Any) {
        self.name = name
        self.content = content
    }
    
    func muscleTo(other: Organ) -> Double {
        guard self.name != other.name else { fatalError("No muscle from (`\(name)`) to (`\(other.name )`).\n*See: `\(#function)`!") }
        if let aWeight = Organ.edges[[self.name, other.name]] { return aWeight }
        fatalError("Muscle from: `\(name)` to `\(other.name)`,\n is not in muscle estruture:\n \(Organ.edges).\n*See: `\(#function)`!")
    }
    
    func set(weight: Double, to other: Organ) {
        guard self.name != other.name else { fatalError("No set muscle for (`\(name)`), to (`\(other.name )`).\n*See: `\(#function)`!") }
        Organ.edges[[self.name, other.name]] = weight
    }
    
    func neighbor(body: Body) -> Organ? {
        var contiguous: Organ?
        var weight: Double?
        for organ in body {
            guard organ != self else { continue }
            let muscle = self.muscleTo(other: organ)
            guard muscle > 0 else { if muscle < 0 { continue } else { return organ } }
            guard let w = weight else {
                contiguous = organ
                weight = muscle
                continue
            }
            if muscle < w {
                contiguous = organ
                weight = muscle
            }
        }
        return contiguous
    }
  
    func neighbors(body: Body) -> [(index: Int, organ: Organ, weakness: Double)] {
        guard body.count > 0 else { return [] }
        var arr = [(index: Int, organ: Organ, weakness: Double)]()
        for (idx, organ) in body.enumerated() {
            guard organ != self else { continue }
            let weakness = self.muscleTo(other: organ)
            guard weakness > 0 else { continue }
            arr.append((idx, organ, weakness))
        }
        arr.sort { $0.weakness < $1.weakness }
        return arr
    }
    
    func neighbors(body: Body, maxWeakness: Double) -> [(index: Int, organ: Organ, weakness: Double)] {
        guard body.count > 0 else { return [] }
        var arr = [(index: Int, organ: Organ, weakness: Double)]()
        for (idx, organ) in body.enumerated() {
            guard organ != self else { continue }
            let weakness = self.muscleTo(other: organ)
            guard weakness > 0, weakness <= maxWeakness else { continue }
            arr.append((idx, organ, weakness))
        }
        arr.sort { $0.weakness < $1.weakness }
        return arr
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    var str: String {
        return name
    }
    
    static func relax() {
        Organ.edges = [[String] : Double]()
        Organ.uniqueBody = [String : Organ]()
    }
    
    static func == (lhs: Organ, rhs: Organ) -> Bool {
        return lhs.name == rhs.name
    }
    
    static func < (lhs: Organ, rhs: Organ) -> Bool {
        return lhs.name < rhs.name
    }
    
    fileprivate static func create(name: String, content: Any) -> Organ {
        if !name.isEmpty {
            if let organ = Organ.uniqueBody[name] {
                return organ
            }
            let newOrgan = Organ(name: name, core: content)
            Organ.uniqueBody[name] = newOrgan
            return newOrgan
        } else {
            fatalError("`\(name)` is empty.\n*See: `\(#function)`!")
        }
    }
}

typealias Body = [Organ]
extension Body {
    
    mutating func appendOrgan(name: String, content core: Any) {
        let organ = Organ.create(name: name, content: core)
        self.append(organ)
    }
    
    func index(of organName: String) -> Int? {
        for i in 0 ..< count {
            if self[i].name == organName {
                return i
            }
        }
        return nil
    }
    
    func organ(by name: String) -> Organ? {
        if !name.isEmpty, let organ = Organ.uniqueBody[name] {
            return organ
        }
        return nil
    }
    
    func muscleUltra(farest: Bool) -> Muscle? {
        if farest {
            return self.muscles().sorted(by: { $0.weakness > $1.weakness } ).first
        } else {
            return self.muscles().sorted(by: { $0.weakness < $1.weakness } )[at: 1]
        }
    }
    
    func muscles() -> Muscles {
        var arr = Muscles()
        guard self.count > 1 else { return arr }
        var previous = last
        for (i, actual) in self.enumerated() {
            if let prev = previous {
                let w = prev.muscleTo(other: actual)
                arr.append(Muscle(index: i, previous: prev, weakness: w, actual: actual))
            }
            previous = actual
        }
        return arr
    }
    
    func std() -> Double {
        var arr = [Double]()
        var previous = last
        for actual in self {
            if let prev = previous { arr.append(prev.muscleTo(other: actual)) }
            previous = actual
        }
        let standardDeviation = arr.std()
        return standardDeviation
    }
    
    func peakests() -> Peaks {
        var arr = Peaks()
        let tot = self.count
        guard tot > 3 else { return arr }
        let body = self
        let bodyAverage = body.average()
        for (idx, curr) in body.enumerated() {
            let prev = body[mod: idx - 1]
            let next = body[mod: idx + 1]
            let ab = prev.muscleTo(other: curr)
            let bc = curr.muscleTo(other: next)
            let ac = prev.muscleTo(other: next)
            let abc = ab + bc, doubleAverage = 2 * bodyAverage
            guard ab > 0, bc > 0, ac > 0, abc > doubleAverage else { continue }
            let sharpen = 1 - doubleAverage / abc
            guard 0...1 ~= sharpen else { continue }
            let peak = Peak(index: idx,
                            prevOrgan: prev, currOrgan: curr, nextOrgan: next,
                            prevEdge: ab, nextEdge: bc, oposEdge: ac,
                            sharpening: sharpen)
            arr.append(peak)
        }
        arr.sort { $0.sharpening > $1.sharpening }
        return arr
    }
    
    func flatCandidates() -> [(peakIdx: Int, neigborIdx: Int, costRate: Double)] {
        let t = BenchTimer()
        var candidates = [(peakIdx: Int, neigborIdx: Int, costRate: Double)]()
        let peaks = self.peakests()
        for peak in peaks {
            guard t.elapsed < 0.010 else { break }
            guard peak.prevEdge > 0, peak.nextEdge > 0, peak.oposEdge > 0 else { continue }
            let actualCost = peak.prevEdge + peak.nextEdge
            var neibhborCandidates = [(peakIdx: Int, neigborIdx: Int, costRate: Double)]()
            let s = BenchTimer()
            for neighbor in peak.neighbors(body: self, maximum: self.average()) {
                guard neighbor.weakness > 0 else { continue }
                let newCost = peak.oposEdge + neighbor.weakness
                guard newCost < actualCost else { continue }
                let costRate = newCost / actualCost
                guard 0...1 ~= costRate else { continue }
                let candidate = (peakIdx: peak.index, neigborIdx: neighbor.index, costRate: costRate)
                neibhborCandidates.append(candidate)
            }
            neibhborCandidates.sort { $0.costRate < $1.costRate }
            for neibhborCandidate in neibhborCandidates {
                guard s.elapsed < 0.005 else { break }
                candidates.append(neibhborCandidate)
            }
            //=print("\ng\(neibhborCandidates.count) \ts_\(s.milliseconds.zeros(0))", terminator: " ")
        }
        candidates.sort { $0.costRate < $1.costRate }
        //=print("\nf\(candidates.count) \tt_\(t.milliseconds.zeros(0))", terminator: " ")
        return candidates
    }
    
    var str: String {
        var ret = "["
        for organ in self {
            ret += " " + organ.str + ","
        }
        return ret + "]"
    }
}

struct Muscle: Comparable {
    
    let index: Int
    let previous: Organ
    let weakness: Double
    let actual: Organ
    
    func isRelated(to other: Muscle) -> Bool {
        if actual == other.actual || actual == other.previous {
            return true
        }
        return previous == other.actual || previous == other.previous
    }
    
    static func < (lhs: Muscle, rhs: Muscle) -> Bool {
        return lhs.weakness < rhs.weakness
    }
    
    var str: String {
        return "(index: \(index), previous: \(previous.str), weakness: \(weakness.zeros(1)), actual: \(actual.str))"
    }
}

typealias Muscles = [Muscle]
extension Muscles {
    
    func nears(to muscle: Muscle) -> [(muscle: Muscle, weight: Double)] {
        var arr = [(muscle: Muscle, weight: Double)]()
        for edge in self {
            guard Swift.min(edge.weakness, muscle.weakness) > 0,
                !muscle.isRelated(to: edge) else { continue }
            let lig0 = edge.previous.muscleTo(other: muscle.previous)
            let lig1 = edge.actual.muscleTo(other: muscle.actual)
            let lig2 = edge.previous.muscleTo(other: muscle.actual)
            let lig3 = edge.actual.muscleTo(other: muscle.previous)
            guard Swift.min(lig0, lig1, lig2, lig3) > 0 else { continue }
            arr.append((muscle: edge, weight: lig0 + lig1 + lig2 + lig3))
        }
        return arr.sorted { $0.weight < $1.weight }
    }
    
    func weakests() -> Muscles {
        return sorted { $0.weakness > $1.weakness }
    }
    
    var str: String {
        var ans = "Muscles: ["
        for muscle in self {
            ans += muscle.str
        }
        return ans
    }
}

typealias Peaks = [Peak]
struct Peak: Comparable {
    
    let index: Int
    let prevOrgan: Organ
    let currOrgan: Organ
    let nextOrgan: Organ
    let prevEdge: Double
    let nextEdge: Double
    let oposEdge: Double
    let sharpening: Double
    
    func neighbors(body: Body, maximum: Double) -> [(index: Int, organ: Organ, weakness: Double)] {
        var neighbors = currOrgan.neighbors(body: body, maxWeakness: maximum)
        neighbors = neighbors.filter { $0.organ != prevOrgan && $0.organ != nextOrgan }
        neighbors.sort { $0.weakness < $1.weakness }
        return neighbors
    }
    
    var str: String {
        return "(index: \(index), prevOrgan: \(prevOrgan.name), currOrgan: \(currOrgan.name), nextOrgan: \(nextOrgan.name), prevEdge: \(prevEdge.zeros(1)), nextEdge: \(nextEdge.zeros(1)), oposEdge: \(oposEdge.zeros(1)), sharpening: \(sharpening.zeros(3)))"
    }
    
    static func < (lhs: Peak, rhs: Peak) -> Bool {
        return lhs.sharpening < rhs.sharpening
    }
}
