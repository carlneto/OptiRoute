protocol Fitness {
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
    
    func closest(body: Body) -> Organ {
        var closestOrgan = self
        var weight: Double?
        for org in body {
            let muscle = muscleTo(other: org)
            guard let w = weight else {
                closestOrgan = org
                weight = muscle
                continue
            }
            if muscle < w {
                closestOrgan = org
                weight = muscle
            }
        }
        return closestOrgan
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

typealias Body = [Organ]

extension Body: Fitness {
    
    mutating func inserted(name: String, content core: Any) -> Organ {
        let organ = Organ.create(name: name, content: core)
        self.append(organ)
        return organ
    }
    
    func generatePeople(size: Int) -> People {
        var result = People()
        if size > 0 {
            for _ in 0 ..< size {
                result.append(Person(body: self.shuffle()))
            }
        }
        return result
    }
    
    var closestPair: (o1: Organ, o2: Organ, weight: Double)? {
        var left: Organ?
        var right: Organ?
        var best: Double?
        for o1 in self {
            for o2 in self {
                guard o1 != o2 else { continue }
                let weight = o1.muscleTo(other: o2)
                guard let bestWeight = best else {
                    left = o1
                    right = o2
                    best = weight
                    continue
                }
                guard weight > 0, weight < bestWeight else { continue }
                left = o1
                right = o2
                best = weight
            }
        }
        guard let l = left, let r = right,  let w = best else { return nil }
        return (o1: l, o2: r, weight: w)
    }
    
    var str: String {
        var ret = "["
        for organ in self {
            ret += " " + organ.str + ","
        }
        return ret + "]"
    }
}
