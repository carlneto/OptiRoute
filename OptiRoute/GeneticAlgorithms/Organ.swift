import UIKit

protocol Fitness {
    init(content: Any, isRound: Bool)
    func setWeights(isRound: Bool)
}

class Organ: Equatable, Hashable, Comparable {
    
    private static var muscles = [[String] : Double]()
    
    private static var body = [String : Organ]()
    
    private (set) var name: String
    
    let content: Any
    
    private init(name: String, core content: Any) {
        self.name = name
        self.content = content
    }
    
    func muscleTo(other: Organ) -> Double {
        if let aWeight = Organ.muscles[[self.name, other.name]] { return aWeight }
        fatalError("Muscle from: `\(name)` to `\(other.name)`,\n is not in muscle estruture:\n \(Organ.muscles).\n*See: `\(#function)`!")
    }
    
    func set(weight: Double, to other: Organ) {
        Organ.muscles[[self.name, other.name]] = weight
        Organ.muscles[[other.name, self.name]] = weight
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
    
    func neighbors(body: Body) -> [(index: Int, organ: Organ, muscle: Double)] {
        guard body.count > 0 else { return [] }
        var neighbors = [(index: Int, organ: Organ, muscle: Double)]()
        for (idx, organ) in body.enumerated() {
            guard organ != self else { continue }
            let muscle = muscleTo(other: organ)
            guard muscle > 0 else { continue }
            let neighbor = (idx, organ, muscle)
            neighbors.append(neighbor)
        }
        neighbors.sort { $0.muscle < $1.muscle }
        return neighbors
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    var str: String {
        return name
    }
    
    static func relaxMuscles() {
        Organ.muscles = [[String] : Double]()
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
    let muscle: Double
    let actual: Organ
    
    func equalDirectionless(other: Muscle) -> Bool {
        if actual == other.actual && previous == other.previous {
            return true
        }
        return actual == other.previous && previous == other.actual
    }
    
    func isRelated(to other: Muscle) -> Bool {
        if actual == other.actual || actual == other.previous {
            return true
        }
        return previous == other.actual || previous == other.previous
    }
    
    var str: String {
        return "(index: \(index), previous: \(previous.str), muscle: \(muscle.zeros(1)), actual: \(actual.str))"
    }

    static func < (lhs: Muscle, rhs: Muscle) -> Bool {
        return lhs.muscle < rhs.muscle
    }
}

typealias Body = [Organ]

extension Body: Fitness {
    
    mutating func inserted(name: String, content core: Any) -> Organ {
        let organ = Organ.create(name: name, content: core)
        self.append(organ)
        return organ
    }
    
    func muscle(farest: Bool) -> (one: Organ, two: Organ, muscle: Double)? {
        var one: Organ?
        var two: Organ?
        var muscle: Double?
        for o1 in self {
            for o2 in self {
                guard o1 != o2 else { continue }
                let bond = o1.muscleTo(other: o2)
                guard let saved = muscle else {
                    one = o1
                    two = o2
                    muscle = bond
                    continue
                }
                guard farest ? bond > saved : bond < saved else { continue }
                one = o1
                two = o2
                muscle = bond
            }
        }
        guard let o1 = one, let o2 = two,  let brawn = muscle else { return nil }
        return (one: o1, two: o2, muscle: brawn)
    }
    
    func muscles() -> [Muscle] {
        var result = [Muscle]()
        var previous = last
        for (idx, actual) in self.enumerated() {
            if let previous = previous {
                result.append(Muscle(index: idx, previous: previous, muscle: previous.muscleTo(other: actual), actual: actual))
            }
            previous = actual
        }
        return result
    }
    
    var str: String {
        var ret = "["
        for organ in self {
            ret += " " + organ.str + ","
        }
        return ret + "]"
    }
}
