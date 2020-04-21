import UIKit

protocol Fitness {
    init(content: Any, isRound: Bool)
    func setWeights(isRound: Bool)
}

struct Organ: Equatable, Hashable, Comparable {
    
    private static var edges = [[String] : Double]()
    
    private static var body = [String : Organ]()
    
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
        Organ.edges[[other.name, self.name]] = weight
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
            let neighbor = (idx, organ, weakness)
            arr.append(neighbor)
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
            if let organ = Organ.body[name] {
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
    
    func ligaments(to muscle: Muscle) -> [(muscle: Muscle, flaccidity: Double)] {
        var arr = [(muscle: Muscle, flaccidity: Double)]()
        for edge in self {
            guard !muscle.isRelated(to: edge) else { continue }
            let lig0 = muscle.previous.muscleTo(other: edge.previous)
            let lig1 = muscle.actual.muscleTo(other: edge.actual)
            let lig2 = muscle.previous.muscleTo(other: edge.actual)
            let lig3 = muscle.actual.muscleTo(other: edge.previous)
            if Swift.min(lig0, lig1, lig2, lig3) > 0 {
                arr.append((muscle: edge, flaccidity: lig0 + lig1 + lig2 + lig3))
            }
        }
        return arr
    }
    
    func glued(to muscle: Muscle) -> [(muscle: Muscle, flaccidity: Double)] {
        return ligaments(to: muscle).sorted { $0.flaccidity < $1.flaccidity }
    }
    
    func weakests() -> Muscles {
        return sorted { $0.weakness > $1.weakness }
    }
}

typealias Peaks = [Peak]
struct Peak: Comparable {
    
    let index: Int
    let prevOrgan: Organ
    let organ: Organ
    let nextOrgan: Organ
    let prevEdge: Double
    let nextEdge: Double
    let oposEdge: Double
    let sharpening: Double
    
    func neighbors(body: Body) -> [(index: Int, organ: Organ, weakness: Double)] {
        let neighbors = organ.neighbors(body: body)
        return neighbors.filter { $0.organ != prevOrgan && $0.organ != nextOrgan && $0.weakness > 0 }
    }
    
    var str: String {
        return "(index: \(index), prevOrgan: \(prevOrgan.name), organ: \(organ.name), nextOrgan: \(nextOrgan.name), prevEdge: \(prevEdge.zeros(1)), nextEdge: \(nextEdge.zeros(1)), oposEdge: \(oposEdge.zeros(1)), sharpening: \(sharpening.zeros(3)))"
    }
    
    static func < (lhs: Peak, rhs: Peak) -> Bool {
        return lhs.sharpening < rhs.sharpening
    }
}

typealias Body = [Organ]
extension Body: Fitness {
    
    mutating func inserted(name: String, content core: Any) -> Organ {
        let organ = Organ.create(name: name, content: core)
        self.append(organ)
        return organ
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
        var previous = last
        for (idx, actual) in self.enumerated() {
            if let prev = previous {
                let w = prev.muscleTo(other: actual)
                arr.append(Muscle(index: idx, previous: prev, weakness: w, actual: actual))
            }
            previous = actual
        }
        return arr
    }
    
    func peakests() -> Peaks {
        var arr = Peaks()
        let tot = self.count
        let body = self
        guard tot > 3 else { return [] }
        for (idx, item) in body.enumerated() {
            let prev = body[mod: idx - 1]
            let next = body[mod: idx + 1]
            let prevEdge = item.muscleTo(other: prev)
            let nextEdge = item.muscleTo(other: next)
            let oposEdge = prev.muscleTo(other: next)
            let sharpen = 1 - oposEdge / (prevEdge + nextEdge)
            let peak = Peak(index: idx,
                            prevOrgan: prev, organ: item, nextOrgan: next,
                            prevEdge: prevEdge, nextEdge: nextEdge, oposEdge: oposEdge,
                            sharpening: sharpen)
            arr.append(peak)
        }
        arr.sort { $0.sharpening > $1.sharpening }
        return arr
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
