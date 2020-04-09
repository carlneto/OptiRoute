protocol Fitness {
    func setWeights()
}

class Organ: Equatable {
    
    private static var weights = [[String] : Double]()
    
    private static var body = [String : Organ]()
    
    private (set) var name: String
    
    let content: Any
    
    private init(name: String, core content: Any) {
        self.name = name
        self.content = content
    }
    
    func weightTo(other: Organ) -> Double {
        if let aWeight = Organ.weights[[self.name, other.name]] {
            return aWeight
        }
        fatalError("Weight from: `\(name)` to `\(other.name)`,\n is not in weights:\n \(Organ.weights).\n*See: `\(#function)`!")
    }
    
    func set(weight: Double, to other: Organ) {
        Organ.weights[[self.name, other.name]] = weight
        Organ.weights[[other.name, self.name]] = weight
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
}
