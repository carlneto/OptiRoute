protocol Fitness {
    func setWeights()
}

class Organ: Equatable, Hashable {
    
    private static var edges = [[String] : Double]()
    
    private static var body = [String : Organ]()
    
    private (set) var name: String
    
    let content: Any
    
    private init(name: String, core content: Any) {
        self.name = name
        self.content = content
    }
    
    func edgeTo(other: Organ) -> Double {
        if let aWeight = Organ.edges[[self.name, other.name]] { return aWeight }
        fatalError("Weight from: `\(name)` to `\(other.name)`,\n is not in weights:\n \(Organ.edges).\n*See: `\(#function)`!")
    }
    
    func set(weight: Double, to other: Organ) {
        Organ.edges[[self.name, other.name]] = weight
        Organ.edges[[other.name, self.name]] = weight
    }
    
    static func clearEdges() {
        edges = [[String] : Double]()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: Organ, rhs: Organ) -> Bool {
        return lhs.name == rhs.name
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
}
