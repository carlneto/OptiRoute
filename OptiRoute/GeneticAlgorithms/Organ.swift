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
    
    func generate(size: Int) -> [Body] {
        var result = Set<Body>()
        if size > 0 {
            while result.count < size {
                result.insert(self.shuffle())
            }
        }
        return result.compactMap { Body($0) }
    }
    
    var sortFromFirst: Body {
        guard let first = self.first else { return self }
        return sort(from: first)
    }
    
    var sortFromBorders: Body {
        guard let first = self.first, let last = self.last else { return self }
        return sort(from: first, and: last)
    }
    
    func sortFromFarestPair(hugging: Bool = false) -> Body {
        guard let pair = farestPair else { return self }
        let organs = sort(from: pair.one, and: hugging ? pair.two : nil)
        return organs
    }
    
    private func sort(from one: Organ, and two: Organ? = nil) -> Body {
        let hugging = two != nil
        var initial = self
        var organs = [Organ]()
        func move(organ: Organ) -> Organ {
            guard let idx = initial.firstIndex(of: organ) else { return organ }
            let newOrgan = initial.remove(at: idx)
            organs.append(newOrgan)
            return newOrgan
        }
        var o1 = move(organ: one)
        var o2 = two ?? one
        if hugging {
            o2 = move(organ: o2)
        }
        while organs.count < self.count {
            o1 = move(organ: o1.neighbor(body: initial))
            if hugging {
                o2 = move(organ: o2)
            }
        }
        if hugging {
            organs.rotate(offset: 1)
        }
        return organs
    }
    
    private var farestPair: (one: Organ, two: Organ, muscle: Double)? {
        var one: Organ?
        var two: Organ?
        var muscle: Double?
        for o1 in self {
            for o2 in self {
                guard o1 != o2 else { continue }
                let bond = o1.muscleTo(other: o2)
                guard let weakest = muscle else {
                    one = o1
                    two = o2
                    muscle = bond
                    continue
                }
                guard bond > weakest else { continue }
                one = o1
                two = o2
                muscle = bond
            }
        }
        guard let o1 = one, let o2 = two,  let brawn = muscle else { return nil }
        return (one: o1, two: o2, muscle: brawn)
    }
    
    var str: String {
        var ret = "["
        for organ in self {
            ret += " " + organ.str + ","
        }
        return ret + "]"
    }
}
