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
        let sorted = edges.sorted { $0.muscle > $1.muscle }
        var limit = Int(Double(self.count) * 0.75)
        let isFirst = Bool.arcRandom && Bool.arcRandom
        for farest in sorted {
            guard limit > 0 else { break }
            var pairs = [(muscle: Muscle, flaccid: Double)]()
            for edge in edges {
                guard !farest.isRelated(to: edge) else { continue }
                let ligament0 = farest.previous.muscleTo(other: edge.previous)
                let ligament1 = farest.actual.muscleTo(other: edge.actual)
                let ligament2 = farest.previous.muscleTo(other: edge.actual)
                let ligament3 = farest.actual.muscleTo(other: edge.previous)
                if Swift.min(ligament0, ligament1, ligament2, ligament3) > 0 {
                    pairs.append((muscle: edge, flaccid: ligament0 + ligament1 + ligament2 + ligament3))
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
    
    func sortedSolos() -> [Body] {
        var body = self
        let tot = body.count
        var bodies = [Body]()
        guard tot > 3 else { return bodies }
        let isolateds = body.alones()
        let itrs = Int(Double(isolateds.count) * 0.25)
        let isAloneRemoved = Bool.arcRandom
        for i in 0 ..< itrs {
            let alone = isolateds[i]
            let itself = alone.itself
            let neighbors = itself.neighbors(body: body)
            for neighbor in neighbors {
                let near = neighbor.organ
                if near != alone.prev, near != alone.next, let nearIdx = body.firstIndex(of: near) {
                    if isAloneRemoved {
                        body.insert(body.remove(at: alone.index), at: nearIdx)
                    } else {
                        body.insert(body.remove(at: nearIdx), at: alone.index)
                    }
                    break
                }
            }
            bodies.append(body)
        }
        return bodies
    }
    
    private func alones() -> [(index: Int, prev: Organ, itself: Organ, next: Organ, nearEdges: Double)] {
        var lones = [(index: Int, prev: Organ, itself: Organ, next: Organ, nearEdges: Double)]()
        let tot = self.count
        guard tot > 3 else { return [] }
        var prevOrg = self[tot - 1]
        var prevEdge = self[0].muscleTo(other: prevOrg)
        for i in 0 ..< tot {
            let nextIdx = (i + 1) % tot
            let actualOrg = self[i]
            let nextOrg = self[nextIdx]
            let nextEdge = actualOrg.muscleTo(other: nextOrg)
            lones.append((index: i, prev: prevOrg, itself: actualOrg, next: nextOrg, nearEdges: prevEdge + nextEdge))
            prevOrg = actualOrg
            prevEdge = nextEdge
        }
        lones.sort { $0.nearEdges > $1.nearEdges }
        return lones
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
