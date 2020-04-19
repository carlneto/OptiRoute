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
        guard let pair = pair(farest: !ascending) else { return self }
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
    
    private func pair(farest: Bool) -> (one: Organ, two: Organ, muscle: Double)? {
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
    
    func sortedSolos() -> [Body] {
        var body = self
        let tot = body.count
        var bodies = [Body]()
        guard tot > 3 else { return bodies }
        let isolateds = body.alones()
        let itrs = isolateds.count / 5
        let isAloneRemoved = Bool.arcRandom
        for i in 0 ..< itrs {//Swift.min(isolateds.count, 15) {
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
            //bodies.append(body.sorted(from: alone.prev))
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
