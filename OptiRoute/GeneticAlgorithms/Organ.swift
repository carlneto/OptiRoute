import UIKit

struct Organ: Equatable, Hashable, Comparable {
    
    private static var edges = [[String] : Double]()
    private static var uniqueBody = [String : Organ]()
    
    private (set) var name: String
    
    let content: Any
    
    private init(name: String, core content: Any) {
        self.name = name
        self.content = content
    }
    
    func muscleTo(other: Organ) -> Double {
        if let aWeight = Organ.edges[[self.name, other.name]] { return aWeight }
        fatalError("Muscle from: `\(name)` to `\(other.name)`,\n is not in muscle estruture:\n \(Organ.edges).\n*See: `\(#function)`!")
    }
    
    func set(weight: Double, to other: Organ) {
        Organ.edges[[self.name, other.name]] = weight
    }
    
    func neighbor(body: Body) -> Organ {
        var contiguous = self
        var weight: Double?
        for organ in body {
            let muscle = muscleTo(other: organ)
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
            let weakness = muscleTo(other: organ)
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
    
    static func relaxMuscles() {
        Organ.edges = [[String] : Double]()
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
            return Organ(name: name, core: content)
        } else {
            fatalError("`\(name)` is empty.\n*See: `\(#function)`!")
        }
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

typealias Body = [Organ]
extension Body {
    
    func index(of organName: String) -> Int? {
        for i in 0 ..< count {
            if self[i].name == organName {
                return i
            }
        }
        return nil
    }
    
    mutating func appendOrgan(name: String, content core: Any) {
        let organ = Organ.create(name: name, content: core)
        self.append(organ)
    }
    
    func muscleUltra(farest: Bool) -> Muscle? {
        var one: Organ?
        var two: Organ?
        var index: Int?
        var weakness: Double?
        for o1 in self {
            for (idx2, o2) in self.enumerated() {
                guard o1 != o2 else { continue }
                let bond = o1.muscleTo(other: o2)
                guard let saved = weakness else {
                    one = o1
                    two = o2
                    index = idx2
                    weakness = bond
                    continue
                }
                guard farest ? bond > saved : bond < saved else { continue }
                one = o1
                two = o2
                index = idx2
                weakness = bond
            }
        }
        guard let i2 = index, let o1 = one, let o2 = two,  let flaccidity = weakness else { return nil }
        return Muscle(index: i2, previous: o1, weakness: flaccidity, actual: o2)
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
    
    func flatCandidates(perPeak tries: Int) -> [(peakIdx: Int, neigborIdx: Int, costRate: Double)] {
        var candidates = [(peakIdx: Int, neigborIdx: Int, costRate: Double)]()
        let peaks = self.peakests()
        for peak in peaks {
            guard peak.prevEdge > 0, peak.nextEdge > 0, peak.oposEdge > 0 else { continue }
            let actualCost = peak.prevEdge + peak.nextEdge
            var neibhborCandidates = [(peakIdx: Int, neigborIdx: Int, costRate: Double)]()
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
            for (i, neibhborCandidate) in neibhborCandidates.enumerated() {
                guard i < tries else { break }
                candidates.append(neibhborCandidate)
            }
        }
        candidates.sort { $0.costRate < $1.costRate }
        return candidates
    }
    
    var prt: String {
        var ret = "[\n"
        for (i, a) in self.enumerated() {
            let b = self[mod: self.modIndex(i + 1)]
            ret += "\(a.name)\t\t(\(a.muscleTo(other: b).zeros(1)))\t\t\(b.name)\n"
        }
        return ret + "]"
    }
    
    var str: String {
        var ret = "["
        for organ in self {
            ret += " " + organ.str + ","
        }
        return ret + "]"
    }
}
