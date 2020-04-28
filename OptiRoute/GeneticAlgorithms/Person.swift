import UIKit

class Person: Hashable {
    
    let body: Body
    
    private var _weight: Double?
    var weight: Double {
        if _weight == nil { _weight = body.calculateWeight() }
        return _weight ?? 0.0
    }
    
    init(body: Body) {
        self.body = body
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
    
    func calculateWeight() -> Double {
        var result: Double = 0.0
        var previousOrgan = last
        forEach { organ in
            if let previousOrgan = previousOrgan { result += previousOrgan.muscleTo(other: organ) }
            previousOrgan = organ
        }
        return result
    }
    
    func progress(from bodies: Bodies) -> String {
        let progrss = bodies.best() - self.calculateWeight()
        if progrss < 0 {
            return " \(bodies.count) \t\(progrss.zeros(0))"
        }
        return " \(bodies.count) \t-0"
    }
    
    func average() -> Double {
        return self.calculateWeight() / Double(self.count)
    }
    
    /// Body operators
    
    func sort() -> [Body] {
        //return []
        //=let t = BenchTimer()
        let bodies = [self,
                      sortedFirst(),
                      sortedLast(),
                      sortedBoth(),
                      sorted(fromCenter: true, both: true),
                      sorted(fromCenter: true, both: false),
                      sorted(fromCenter: false, both: true),
                      sorted(fromCenter: false, both: false)]
        //=print("\na\(self.progress(from: bodies)) t_\(t.milliseconds.zeros(0))", terminator: " ")
        return bodies
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
    
    func sorted(fromCenter: Bool, both: Bool) -> Body {
        guard let pair = muscleUltra(farest: !fromCenter) else { return self }
        let organs = sorted(from: pair.previous, and: both ? pair.actual : nil)
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
            organs.rotate(shift: 1)
        }
        return organs
    }
    
    func collect() -> [Body] {
        //return []
        //let t = BenchTimer()
        var bodies = [Body]()
        let tot = self.count
        guard tot > 3 else { return bodies }
        let weaknessMax = self.average()
        var candidates = [(from: String, to: String, gain: Double)]()
        var body = self
        for (i, a) in body.enumerated() {
            //guard t.elapsed < 0.020 else { break }
            let c = body[mod: i]
            let ac = a.muscleTo(other: c)
            let ab_s = a.neighbors(body: body, maxWeakness: weaknessMax)
            var neighborName = ""
            var gainWeight = Double(Int.max)
            for ab in ab_s {
                let b = ab.organ
                guard b != c else { continue }
                let bc = b.muscleTo(other: c)
                let a2 = body[mod: ab.index - 1], b2 = b, c2 = body[mod: ab.index + 1]
                let ab2 = a2.muscleTo(other: b2), bc2 = b2.muscleTo(other: c2), ac2 = a2.muscleTo(other: c2)
                let oldCost = ac + ab2 + bc2, newCost = ab.weakness + bc + ac2
                guard newCost < oldCost else { continue }
                let aWeight = newCost - oldCost
                guard aWeight < gainWeight else { continue }
                gainWeight = aWeight
                neighborName = ab.organ.name
            }
            candidates.append((from: neighborName, to: c.name, gain: gainWeight))
        }
        guard !candidates.isEmpty else { return bodies }
        candidates.sort { $0.gain < $1.gain }
        var names = Set<String>()
        for candidate in candidates {
            if !names.insert(candidate.from).inserted || !names.insert(candidate.to).inserted {
                continue
            }
            guard let fromIdx = body.index(of: candidate.from),
                let toIdx = body.index(of: candidate.to) else { continue }
            body.move(from: fromIdx, to: toIdx, before: true)
            guard body.count == self.count else { break }
            bodies.append(body)
        }
        //=print("\nc\(self.progress(from: bodies)) \tt_\(t.milliseconds.zeros(0))", terminator: " ")
        return bodies//.swapped()
    }
    
    func uncross(maxLenght: Double = 2.5, tries: Int = 20) -> [Body] {
        //return []
        let t = BenchTimer()
        var bodies = [Body]()
        guard self.count > 3 else { return bodies }
        let limit = Swift.max(2, Int(Double(self.count * 2) * maxLenght))
        let muscles = self.muscles()
        let weakests = muscles.weakests()
        for weakest in weakests {
            guard bodies.count < limit, t.elapsed < 0.012 else { break }
            let nears = muscles.nears(to: weakest)
            var maxNears = tries
            for near in nears {
                guard bodies.count < limit, maxNears > 0 else { break }
                if let aBody = self.reversed(between: weakest.index - 1, and: near.muscle.index) {
                    bodies.append(aBody)
                    maxNears -= 1
                }
            }
        }
        //=print("\nu\(self.progress(from: bodies)) \tt_\(t.milliseconds.zeros(0))", terminator: " ")
        return bodies
    }
    
    func ejected(maxLenght: Double = 5.0, tries: Int = 20) -> [Body] {
        //return []
        let t = BenchTimer()
        let tot = self.count
        var bodies = [Body]()
        guard self.count > 3 else { return bodies }
        let limit = Swift.max(2, Int(Double(self.count) * maxLenght))
        var indexes = Set<Int>()
        var body1 = self, body2 = self
        for candidate in self.flatCandidates(perPeak: tries) {
            guard bodies.count < limit, t.elapsed < 0.015 else { break }
            if !indexes.insert(candidate.peakIdx).inserted || !indexes.insert(candidate.neigborIdx).inserted ||
                !indexes.insert(candidate.neigborIdx - 1).inserted {
                body1 = self
                body2 = self
                indexes = Set<Int>()
            }
            body1.move(from: candidate.peakIdx, to: candidate.neigborIdx, before: false)
            body2.move(from: candidate.peakIdx, to: candidate.neigborIdx, before: true)
            guard body1.count == tot, body2.count == tot else {
                body1 = self
                body2 = self
                indexes = Set<Int>()
                continue
            }
            bodies.append(body1)
            bodies.append(body2)
        }
        //=print("\ne\(self.progress(from: bodies)) \tt_\(t.milliseconds.zeros(0))", terminator: " ")
        return bodies//.swapped()
    }
    
    func untwists() -> [Body] {
        //return []
        let t = BenchTimer()
        var bodies = [Body]()
        var vip = self
        for i in 4 ..< Swift.min(vip.count / 2, 12) {
            guard t.elapsed < 0.030 else { break }
            if let untwist = vip.untwist(interval: i) {
                bodies.append(untwist)
                vip = untwist
            }
        }
        //=print("\nt\(self.progress(from: bodies)) \tt_\(t.milliseconds.zeros(0))", terminator: " ")
        return bodies
    }
    
    private func untwist(interval: Int) -> Body? {
        let tot = self.count
        var body = self
        guard 3 ..< (body.count / 2) ~= interval else { return nil }
        for i in 0 ..< tot {
            if let costs = body.costs(from: i, by: interval), costs.new < costs.old,
                let aBody = body.reversed(between: i, and: i + interval) {
                body = aBody
            }
        }
        guard body.count == tot else { return nil }
        return body
    }
    
    func costs(from: Int, by interval: Int) -> (old: Double, new: Double)? {
        guard interval > 2 else { return nil }
        func cost(idxs: [Int]) -> Double {
            var tmp = 0.0
            for j in 0 ..< (idxs.count - 1) {
                let o1 = self[mod: idxs[j]], o2 = self[mod: idxs[j + 1]]
                tmp += o1.muscleTo(other: o2)
            }
            return tmp
        }
        let seq = from.sequence(to: from + interval)
        guard seq.straight.count == seq.inverted.count else { return nil }
        let oldCost = cost(idxs: seq.straight), newCost = cost(idxs: seq.inverted)
        return (old: oldCost, new: newCost)
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
