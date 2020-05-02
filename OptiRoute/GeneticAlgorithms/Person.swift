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
    
    var turns: Int {
        let n = body.count
        let x = Double(n)
        var ans = 1.0
        if n < 5 {
            ans = 146
        } else if n < 30 {
            ans = (((2 / 1875 - (11 * (x - 10)) / 187500) * (x - 20) * (x - 15) + 3 / 50) * (x - 25) - 1 / 5) * (x - 30) + 8
        } else if n < 90 {
            ans = 8
        } else if n < 120 {
            ans = (90 - x) / 5 + 7
        }
        return Int(ans.rounded())
    }
    
    var str: String {
        var ret = "Muscles: [\n"
        for (i, a) in self.body.enumerated() {
            let b = self.body[mod: i + 1]
            ret += "\t\t\t\(a.name)\t\t(\(a.muscleTo(other: b).zeros(1)))\t\t\(b.name)\n"
        }
        return ret + "\t\t]"
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
        let body = self.body.mutate(withOther: parentTwo.body, probability: percentage)
        return Person(body: body)
    }
}

extension Body {
    
    func generatePeople(size: Int) -> People {
        var result = People()
        if size > 0 {
            for _ in 0 ..< size {
                result.append(Person(body: self.shuffled()))
            }
        }
        return result
    }
    
    func calculateWeight() -> Double {
        var result: Double = 0.0
        var previousOrgan = self.last
        self.forEach { organ in
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
                      self.sortedFirst(),
                      self.sortedLast(),
                      self.sortedBoth(),
                      self.sorted(fromCenter: true, both: true),
                      self.sorted(fromCenter: true, both: false),
                      self.sorted(fromCenter: false, both: true),
                      self.sorted(fromCenter: false, both: false)]
        //=print("\ns\(self.progress(from: bodies)) t_\(t.elapsed.zeros(3))", terminator: " ")
        return bodies
    }
    
    func sortedFirst() ->  Body {
        guard let first = self.first else { return self }
        return self.sorted(from: first)
    }
    
    func sortedLast() ->  Body {
        guard let last = self.last else { return self }
        return self.sorted(from: last)
    }
    
    func sortedBoth() ->  Body {
        guard let first = self.first, let last = self.last else { return self }
        return self.sorted(from: first, and: last)
    }
    
    func sorted(fromCenter: Bool, both: Bool) -> Body {
        guard let pair = muscleUltra(farest: !fromCenter) else { return self }
        return self.sorted(from: pair.previous, and: both ? pair.actual : nil)
    }
    
    private func sorted(from one: Organ, and two: Organ? = nil) -> Body {
        let tot = self.count
        var baseBody = self
        var organs = [Organ]()
        func move(organ: Organ, toFront: Bool = false) -> Organ {
            guard let idx = baseBody.firstIndex(of: organ) else { return organ }
            let newOrgan = baseBody.remove(at: idx)
            toFront ? organs.insert(newOrgan, at: 0) : organs.append(newOrgan)
            return newOrgan
        }
        if let two = two {
            var o1 = move(organ: one)
            var o2 = move(organ: two)
            while organs.count < tot, baseBody.count > 0 {
                let no1 = o1.neighbor(body: baseBody)
                let no2 = o2.neighbor(body: baseBody)
                let t1 = no1 ?? no2, t2 = no2 ?? no1
                guard let n1 = t1, let n2 = t2 else {
                    organs += baseBody
                    baseBody = []
                    continue
                }
                if n1 != n2 {
                    o1 = move(organ: n1)
                    o2 = move(organ: n2, toFront: true)
                } else {
                    if o1.muscleTo(other: n1) < o2.muscleTo(other: n1) {
                        o1 = move(organ: n1)
                    } else {
                        o2 = move(organ: n1, toFront: true)
                    }
                }
            }
            if let oneIdx = organs.firstIndex(of: one) {
                organs.rotate(shift: oneIdx)
            }
        } else {
            var o1 = move(organ: one)
            while organs.count < tot, baseBody.count > 0, let n1 = o1.neighbor(body: baseBody) {
                o1 = move(organ: n1)
            }
        }
        guard organs.count == tot else { return self }
        return organs
    }
    
    func uncross() -> [Body] {
        //return []
        let t = BenchTimer()
        var bodies = [Body]()
        guard self.count > 3 else { return bodies }
        let muscles = self.muscles()
        let weakests = muscles.weakests()
        var bestWeight = self.calculateWeight()
        for weakest in weakests {
            guard t.elapsed < 0.040 else { break }
            let nears = muscles.nears(to: weakest)
            let s = BenchTimer()
            for near in nears {
                guard s.elapsed < 0.002 else { break }
                if let aBody = self.reversed(between: weakest.index - 1, and: near.muscle.index) {
                    let aBodyWeight = aBody.calculateWeight()
                    if aBodyWeight < bestWeight {
                        bodies.append(aBody)
                        bestWeight = aBodyWeight
                        break
                    }
                }
            }
        }
        //=print("\nu\(self.progress(from: bodies)) \tt_\(t.elapsed.zeros(3))", terminator: " ")
        return bodies
    }
    
    func collect() -> [Body] {
        //return []
        let t = BenchTimer()
        var bodies = [Body]()
        let tot = self.count
        guard tot > 3 else { return bodies }
        var candidates = [(from: String, to: String, gain: Double)]()
        var body = self
        let weaknessMax = body.average() * 2
        for (i, a) in body.enumerated() {
            guard t.elapsed < 0.025 else { break }
            let c = body[mod: i + 1]
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
            guard !neighborName.isEmpty else { continue }
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
        //=print("\nc\(self.progress(from: bodies)) \tt_\(t.elapsed.zeros(3))", terminator: " ")
        return bodies//.swapped()
    }
    
    func release() -> [Body] {
        //return []
        let t = BenchTimer()
        let tot = self.count
        var bodies = [Body]()
        guard self.count > 3 else { return bodies }
        var indexes = Set<Int>()
        var bestWeight = self.calculateWeight()
        var body1 = self, body2 = self
        for candidate in self.flatCandidates() {
            guard t.elapsed < 0.020 else { break }
            if !indexes.insert(candidate.peakIdx).inserted ||
                !indexes.insert(candidate.neigborIdx).inserted ||
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
            func append(aBody: Body, weakness: Double) {
                guard weakness < bestWeight else { return }
                bodies.append(aBody)
                bestWeight = weakness
            }
            append(aBody: body1, weakness: body1.calculateWeight())
            append(aBody: body2, weakness: body2.calculateWeight())
        }
        //=print("\nr\(self.progress(from: bodies)) \tt_\(t.elapsed.zeros(3))", terminator: " ")
        return bodies//.swapped()
    }
    
    func untwists(interval: Int = 12) -> [Body] {
        //return []
        let t = BenchTimer()
        var bodies = [Body]()
        var vip = self
        for i in 4 ... Swift.max(4, interval) {
            guard t.elapsed < 0.020 else { break }
            if let untwist = vip.untwist(interval: i) {
                bodies.append(untwist)
                vip = untwist
            }
            //print("\nx\(self.progress(from: [vip])) i\(i)\tm_\(t.elapsed.zeros(3))", terminator: " ")
        }
        //=print("\nt\(self.progress(from: bodies)) \tt_\(t.elapsed.zeros(3))", terminator: " ")
        return bodies
    }
    
    private func untwist(interval: Int) -> Body? {
        let tot = self.count
        guard tot > 2, 3 ..< Swift.max(3, tot / 2) ~= interval else { return nil }
        var body = self
        for i in 0 ..< tot {
            if let costs = body.costs(from: i, by: interval), costs.new < costs.old,
                let aBody = body.reversed(between: i, and: i + interval) {
                body = aBody
            }
        }
        guard body.count == tot else { return nil }
        return body
    }
    
    private func costs(from: Int, by interval: Int) -> (old: Double, new: Double)? {
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
        return child.mutate(probability: percentage)
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
