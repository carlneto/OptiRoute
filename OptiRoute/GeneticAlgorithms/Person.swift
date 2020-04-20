import UIKit

class Person: Hashable {
    
    let body: Body
    
    private var _weight: Double?
    var weight: Double {
        if _weight == nil { _weight = calculateWeight() }
        return _weight ?? 0.0
    }
    
    init(body: Body) {
        self.body = body
    }
    
    private func calculateWeight() -> Double {
        var result: Double = 0.0
        var previousOrgan = body.last
        body.forEach { organ in
            if let previousOrgan = previousOrgan { result += previousOrgan.muscleTo(other: organ) }
            previousOrgan = organ
        }
        return result
    }
    
    var str: String {
        return body.str
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(body)
    }
    
    static func == (lhs: Person, rhs: Person) -> Bool {
        return lhs.body == rhs.body
    }
    
    /// Person operators
    
    func fitnessProb(withTotalWeight totalWeigh: Double) -> Double {
        return 1 - (weight / totalWeigh)// Probability of being selected from 0 to 1
    }
    
    func mutate(withOther parentTwo: Person, probability percentage: Double) -> Person {
        let finalChild = Person(body: self.body.mutate(withOther: parentTwo.body, probability: percentage))
        return finalChild
    }
}

extension Body {
    
    func generatePeople(size: Int) -> People {
        var result = People()
        if size > 0 {
            for _ in 0 ..< size {
                result.append(Person(body: self.shuffle()))
            }
        }
        return result
    }
    
    func generateBodies(size: Int) -> [Body] {
        var result = Set<Body>()
        if size > 0 {
            while result.count < size {
                result.insert(self.shuffle())
            }
        }
        return result.compactMap { Body($0) }
    }
    
    /// Body operators
    
    func sortedFirst() ->  Body {
        guard let first = self.first else { return self }
        return sorted(from: first)
    }
    
    func sortedLast() ->  Body {
        guard let last = self.last else { return self }
        return sorted(from: last)
    }
    
    func sortedBoth() ->  Body {
        guard let first = self.first, let last = self.last else { return self }
        return sorted(from: first, and: last)
    }
    
    func sortedEach() -> [Body] {
        let body = self
        var bodies = [Body]()
        for organ in body {
            bodies.append(body.sorted(from: organ))
            bodies.append(body.reversed().sorted(from: organ))
        }
        return bodies
    }
    
    func sorted(ascending: Bool, both: Bool) -> Body {
        guard let pair = muscle(farest: !ascending) else { return self }
        let organs = sorted(from: pair.one, and: both ? pair.two : nil)
        return organs
    }
    
    private func sorted(from one: Organ, and two: Organ? = nil) -> Body {
        let hugging = two != nil
        var baseBody = self
        var organs = [Organ]()
        func move(organ: Organ) -> Organ {
            guard let idx = baseBody.firstIndex(of: organ) else { return organ }
            let newOrgan = baseBody.remove(at: idx)
            organs.append(newOrgan)
            return newOrgan
        }
        var o1 = move(organ: one)
        var o2 = two ?? one
        if hugging {
            o2 = move(organ: o2)
        }
        while organs.count < self.count {
            o1 = move(organ: o1.neighbor(body: baseBody))
            if hugging {
                o2 = move(organ: o2.neighbor(body: baseBody))
            }
        }
        if hugging {
            organs.rotate(offset: 1)
        }
        return organs
    }
    
    func uncrossed() -> [Body] {
        var bodies = [Body]()
        let edges = muscles()
        let farests = edges.sorted { $0.muscle > $1.muscle }
        var limit = Int(Double(self.count) * 0.10)
        let isFirst = Bool.arcRandom && Bool.arcRandom
        for farest in farests {
            guard limit > 0 else { break }
            var pairs = [(muscle: Muscle, flaccid: Double)]()
            for edge in edges {
                guard !farest.isRelated(to: edge) else { continue }
                let lig0 = farest.previous.muscleTo(other: edge.previous)
                let lig1 = farest.actual.muscleTo(other: edge.actual)
                let lig2 = farest.previous.muscleTo(other: edge.actual)
                let lig3 = farest.actual.muscleTo(other: edge.previous)
                if Swift.min(lig0, lig1, lig2, lig3) > 0 {
                    pairs.append((muscle: edge, flaccid: lig0 + lig1 + lig2 + lig3))
                }
            }
            pairs.sort { $0.flaccid < $1.flaccid }
            guard let near = pairs.first else { continue }
            var body = self
            if isFirst {
                body.reverse(between: farest.index - 1, and: near.muscle.index)
            } else {
                body.reverse(between: farest.index, and: near.muscle.index - 1)
            }
            bodies.append(body)
            limit -= 1
        }
        return bodies
    }
    
    func smoothed() -> [Body] {
        var bodies = [Body]()
        guard self.count > 3 else { return bodies }
        let peaks = self.peaks()
        let sorted = peaks.sorted { $0.percentage > $1.percentage }
        var limit = Swift.max(3, Int(Double(peaks.count) * 0.10))
        for peak in sorted {
            guard limit > 0 else { break }
            var body = self, other = self
            let neighbors = peak.organ.neighbors(body: body)
            let first = neighbors.first { $0.organ != peak.prevOrgan && $0.organ != peak.nextOrgan && $0.muscle > 0 }
            guard let neighbor = first else { continue }
            other.move(from: peak.index, to: neighbor.index, before: false)
            body.move(from: peak.index, to: neighbor.index, before: true)
            bodies.append(other)
            bodies.append(body)
            limit -= 1
        }
        return bodies
    }
    
    func mutate(withOther bodyTwo: Body, probability percentage: Double) -> Body {
        let child = produceOffspring(secondBody: bodyTwo)
        let finalChild = child.mutate(probability: percentage)
        return finalChild
    }
    
    private func produceOffspring(secondBody: Body) -> Body {
        let firstBody = self
        let slice = Int(arc4random_uniform(UInt32(firstBody.count)))
        var body = Body(firstBody[0..<slice])
        var idx = slice
        while body.count < secondBody.count {
            let organ = secondBody[idx]
            if !body.contains(organ) {
                body.append(organ)
            }
            idx = (idx + 1) % secondBody.count
        }
        return body
    }
    
    private func mutate(probability: Double) -> Body {
        if probability >= Double(Double(arc4random()) / Double(UINT32_MAX)) {
            let firstIdx = Int(arc4random_uniform(UInt32(count)))
            let secondIdx = Int(arc4random_uniform(UInt32(count)))
            var body = self
            body.swapAt(firstIdx, secondIdx)
            return body
        }
        return self
    }
}
