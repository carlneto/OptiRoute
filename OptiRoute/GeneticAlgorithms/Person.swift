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
    
    var description: String {
        var ret = "["
        for organ in body { ret += organ.name + ", " }
        return ret + "]"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(body)
    }
    
    static func == (lhs: Person, rhs: Person) -> Bool {
        return lhs.body == rhs.body
    }
    
    // Probability of being selected from 0 to 1
    func fitnessProb(withTotalWeight totalWeigh: Double) -> Double {
        return 1 - (weight / totalWeigh)
    }
    
    /// Person operators
    
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
    
    func random(size: Int) -> [Body] {
        var result = Set<Body>()
        if size > 0 {
            while result.count < size {
                result.insert(self.shuffle())
            }
        }
        return result.compactMap { Body($0) }
    }
    
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
    
    func swapWorst() -> [Body] {
        guard self.count > 3 else { return [self] }
        var body = self
        var bodies = [Body]()
        let k = 2, size = 2 * k
        var s = 1
        for j in 0..<size {
            var aloneIdx = 0
            var nearEdges = 0.0
            var previousEdge = body[0].muscleTo(other: body[body.count - 1])
            for i in 0 ..< body.count {
                let nextEdge = body[i].muscleTo(other: body[(i + 1) % body.count])
                if nearEdges < previousEdge + nextEdge {
                    nearEdges = previousEdge + nextEdge
                    aloneIdx = i
                }
                previousEdge = nextEdge
            }
            var secondIdx = aloneIdx
            if j < k {
                let nextIdx = (aloneIdx + 1) % body.count
                let nextEdge = body[aloneIdx].muscleTo(other: body[nextIdx])
                let inc = nextEdge * 2 < nearEdges ? 1 : -1
                secondIdx = (aloneIdx + inc + body.count) % body.count
            } else {
                s += 2
                let nextIdx = (aloneIdx + s) % body.count
                let prevIdx = (aloneIdx - s + body.count) % body.count
                let nextEdge = body[aloneIdx].muscleTo(other: body[nextIdx])
                let prevEdge = body[aloneIdx].muscleTo(other: body[prevIdx])
                secondIdx = nextEdge < prevEdge ? prevIdx : nextIdx
            }
            body.swapAt(aloneIdx, secondIdx)
            bodies.append(body)
            if j % (k - 1) == k { body = self }
        }
        return bodies
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
    
    var str: String {
        var ret = "["
        for organ in self {
            ret += " " + organ.str + ","
        }
        return ret + "]"
    }
}
