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
    
    func sortedAll() -> [Body] {
        return [self,
                sortedFirst(),
                sortedLast(),
                sortedBoth(),
                sorted(fromCenter: true, both: true),
                sorted(fromCenter: true, both: false),
                sorted(fromCenter: false, both: true),
                sorted(fromCenter: false, both: false)]
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
            organs.rotate(offset: 1)
        }
        return organs
    }
    
    func distorted(weakestRate: Double = 0.10, nearsCount: Int = 3) -> [Body] {
        var bodies = [Body]()
        let muscles = self.muscles()
        let weakests = muscles.weakests()
        var limit = Swift.max(1, Int(Double(weakests.count) * weakestRate))
        for weakest in weakests {
            guard limit > 0 else { break }
            let nears = muscles.glued(to: weakest)
            var max = nearsCount
            for near in nears {
                guard max > 0 else { break }
                var body1 = self, body2 = self
                body1.reverse(between: weakest.index - 1, and: near.muscle.index)
                body2.reverse(between: weakest.index, and: near.muscle.index - 1)
                bodies.append(body1)
                bodies.append(body2)
                max -= 1
            }
            limit -= 1
            
        }
        return bodies
    }
    
    func flattened(peaksRate: Double = 0.03, neighborsCount: Int = 3) -> [Body] {
        var bodies = [Body]()
        guard self.count > 3 else { return bodies }
        let peaks = self.peakests()
        var limit = Swift.max(1, Int(Double(peaks.count) * peaksRate))
        for peak in peaks {
            guard limit > 0 else { break }
            let neighbors = peak.neighbors(body: self)
            var max = neighborsCount
            for neighbor in neighbors {
                guard max > 0 else { break }
                var body1 = self, body2 = self
                body1.move(from: peak.index, to: neighbor.index, before: false)
                body2.move(from: peak.index, to: neighbor.index, before: true)
                bodies.append(body1)
                bodies.append(body2)
                max -= 1
            }
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
