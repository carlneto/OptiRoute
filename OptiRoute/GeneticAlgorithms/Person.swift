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
    
    func swapAlone() -> [Body] {
        let tot = self.count
        guard tot > 3 else { return [Body]() }
        var body = self
        var bodies = [Body]()
        let lone = body.alone()
        let aloneIdx = lone.index
        let nextIdx = (aloneIdx + 1) % tot
        let prevIdx = (aloneIdx - 1 + tot) % tot
        func insertAt(idx0: Int, idx1: Int) {
            body.swapAt(idx0, idx1)
            bodies.append(body)
            body.swapAt(idx1, idx0)
        }
        insertAt(idx0: aloneIdx, idx1: nextIdx)
        insertAt(idx0: aloneIdx, idx1: prevIdx)
        insertAt(idx0: prevIdx, idx1: nextIdx)
        return bodies
    }
    
    func swapSurroundings(turns: Int) -> [Body] {
        let tot = self.count
        var body = self
        var bodies = [Body]()
        for i in 1 ... turns {
            let aloneIdx = body.alone().index
            let level = i + 1
            guard level < tot else { break }
            if let secondIdx = body[aloneIdx].circumjacent(body: body, after: level) {
                body.insert(body.remove(at: aloneIdx), at: secondIdx)
                bodies.append(body)
            }
        }
        return bodies
    }
    
    private func alone() -> (index: Int, nearEdges: Double) {
        var aloneIdx = 0
        var nearEdges = 0.0
        let tot = self.count
        guard tot > 3 else { return (aloneIdx, nearEdges) }
        var previousEdge = self[0].muscleTo(other: self[tot - 1])
        for i in 0 ..< tot {
            let nextEdge = self[i].muscleTo(other: self[(i + 1) % tot])
            if nearEdges < previousEdge + nextEdge {
                nearEdges = previousEdge + nextEdge
                aloneIdx = i
            }
            previousEdge = nextEdge
        }
        return (aloneIdx, nearEdges)
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
