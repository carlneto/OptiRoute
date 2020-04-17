import UIKit

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
    
    func neighborIndex(body: Body) -> Int {
        var contiguous = 0
        var weight: Double?
        for (idx, organ) in body.enumerated() {
            guard organ != self else { continue }
            let muscle = muscleTo(other: organ)
            guard muscle > 0, let w = weight else {
                contiguous = idx
                weight = muscle
                continue
            }
            if muscle < w {
                contiguous = idx
                weight = muscle
            }
        }
        return contiguous
    }
    
    func neighbors(body: Body) -> [(index: Int, neighbor: Organ, muscle: Double)] {
        guard body.count > 0 else { return [] }
        var neighbors = [(index: Int, neighbor: Organ, muscle: Double)]()
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

typealias Body = [Organ]

extension Body: Fitness {
    
    mutating func inserted(name: String, content core: Any) -> Organ {
        let organ = Organ.create(name: name, content: core)
        self.append(organ)
        return organ
    }
}
