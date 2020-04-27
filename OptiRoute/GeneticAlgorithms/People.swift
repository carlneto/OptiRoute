import UIKit

typealias People = [Person]
extension People {
    
    var totalWeight: Double {
        return self.reduce(0.0, { $0 + $1.weight })
    }
    
    init(from body: Body, size: Int) {
        self.init()
        var ppl = People()
        for sorted in body.sort() { ppl.append(Person(body: sorted)) }
        self.add(people: ppl, vip: Person(body: body), size: size, isLast: false)
        //=print("\ninit: \(count)")
        while count < size / 2 {
            if let child = child(mutation: 0.68, weight: stats().weight) { append(child) }
        }
        //=print("\nv\(self.stats().vip!.weight.zeros(0))\ninitWith: \(count)")
        while count < size {
            append(Person(body: body.shuffle()))
        }
    }
    
    mutating func stats() -> (pop: People, weight: Double, vip: Person?) {
        self.removeDuplicates()
        let weight = totalWeight
        let actual = currentGeneration(totalWeight: weight)
        let first = actual.first
        return (actual, weight, first)
    }
    
    private func currentGeneration(totalWeight weight: Double) -> People {
        let sortByFitnessDESC: (Person, Person) -> Bool = { $0.fitnessProb(withTotalWeight: weight) > $1.fitnessProb(withTotalWeight: weight) }
        let currentGeneration = sorted(by: sortByFitnessDESC)
        return currentGeneration
    }
    
    mutating func add(people: People, vip: Person, size: Int, isLast: Bool) {
        guard !isLast else { return }
        var best: Body {
            let newStats = self.stats()
            if let newVip = newStats.vip {
                return newVip.body.reversed()
            }
            self = people
            return vip.body.rotated(shift: Int(arc4random_uniform(UInt32(vip.body.count))))
        }
        func swap(maxLenght: Int = 30) {
            let t = BenchTimer()
            //=var bodies = [Body]()
            let stts = self.stats()
            let pop = stts.pop
            let limit = self.count + maxLenght
            for aPerson in pop {
                guard self.count < limit, t.elapsed < 0.150 else { break }
                for swapped in aPerson.body.swapped() {
                    append(Person(body: swapped))
                    //=bodies.append(swapped)
                }
            }
            //=print("\ns\(stts.vip!.body.progress(from: bodies)) \tt_\(t.milliseconds.zeros(0))", terminator: " ")
        }
        for uncross in best.uncross() { append(Person(body: uncross)) }
        swap()
        for ejected in best.ejected() { append(Person(body: ejected)) }
        for collect in best.collect() { append(Person(body: collect)) }
        //for uncross in best.uncross() { append(Person(body: uncross)) }
        swap()
        let maxLenght = 32 * size / 100
        if self.count > maxLenght {
            self = Array(self.stats().pop[0..<Swift.min(maxLenght, self.count)])
        }
    }
    
    mutating func addRandom(vip: Person, size: Int, isLast: Bool) {
        guard !isLast else { return }
        self += vip.body.generatePeople(size: size)
    }
    
    mutating func addRoulette(people: People, size: Int, isLast: Bool) {
        guard !isLast else { return }
        for _ in 0 ..< size {
            if let roulette = people.roulette {
                append(roulette.person)
            }
        }
    }
    
    mutating func addChildren(statistics: (pop: People, weight: Double, vip: Person?), size: Int, isLast: Bool) {
        guard !isLast else { return }
        removeDuplicates()
        let probInitial = 0.68
        var mutationProb = probInitial
        repeat {
            if let child = statistics.pop.child(mutation: mutationProb, weight: statistics.weight) {
                append(child)
            }
            if mutationProb == probInitial, count >= size {
                mutationProb = 0.32
                removeDuplicates()
            }
        } while count < size
    }
    
    mutating func removeDuplicates() {
        self = Array(Set(self))
    }
    
    /// People operators
    
    func child(mutation mutationProbability: Double, weight: Double) -> Person? {
        if let parentOne = elitistParent(with: weight), let parentTwo = elitistParent(with: weight) {
            return parentOne.mutate(withOther: parentTwo, probability: mutationProbability)
        }
        return nil
    }
    
    private func elitistParent(with weightTotal: Double) -> Person? {
        let fitness = Double(arc4random()) / Double(UINT32_MAX)
        var currentFitness: Double = 0.0
        var result: Person?
        forEach { body in
            if currentFitness <= fitness {
                currentFitness += (1 - body.weight / weightTotal)
                result = body
            }
        }
        return result
    }
    
    var roulette: (index: Int, person: Person)? {
        let weightTotal = totalWeight
        var pick = drand48()
        for (idx, person) in self.enumerated() {
            pick -= (person.weight / weightTotal)
            if pick <= 0 {
                return (idx, person)
            }
        }
        return nil
    }
}

typealias Bodies = [Body]
extension Bodies {
    
    func best() -> Double {
        var weight = Double(Int.max)
        forEach { body in
            let result = body.calculateWeight()
            weight = Swift.min(weight, result)
        }
        return weight
    }
    
    func progress(from weakness: Double) -> String {
        let progrss = self.best() - weakness
        if progrss < 0 {
            return "\(self.count) \(progrss.zeros(0))"
        }
        return "\(self.count) -0"
    }
    
    func vips(maxLenght: Int) -> (bodies: Bodies, weakness: Double) {
        var bodiesWeakness = [(body: Body, weakness: Double)]()
        forEach { body in
            let result = body.calculateWeight()
            bodiesWeakness.append((body: body, weakness: result))
        }
        bodiesWeakness.sort(by: { $0.weakness < $1.weakness })
        var bodies = Bodies()
        var best = 0.0
        for bodyWeakness in bodiesWeakness {
            if best == 0 {
                best = bodyWeakness.weakness
            }
            guard bodies.count < maxLenght else { break }
            bodies.append(bodyWeakness.body)
        }
        return (bodies, best)
    }
    
    func swapped(maxLenght: Double = 0.33) -> Bodies {
        //return []
        var counter = 0
        let t = BenchTimer()
        var bodies = Bodies()
        for var body in self {
            guard body.count > 3 else { continue }
            let limit = Swift.max(2, Int(Double(body.count) * maxLenght))
            for i in 0 ..< body.count {
                guard self.count < limit else { break }
                let a = body[mod: i], b = body[mod: i + 1], c = body[mod: i + 2], d = body[mod: i + 3]
                let ab = a.muscleTo(other: b), bc = b.muscleTo(other: c), cd = c.muscleTo(other: d)
                let ac = a.muscleTo(other: c), cb = c.muscleTo(other: b), bd = b.muscleTo(other: d)
                guard Swift.min(ab, bc, cd, ac, cb, bc, bd) >= 0 else { continue }
                let old = ab + bc + cd, new = ac + cb + bd
                if new < old {
                    body.swapIndexes(i: i + 1, j: i + 2)
                    counter += 1
                }
                guard body.count == self.count else { break }
                bodies.append(body)
            }
        }
        print("\nz\(counter) \tt_\(t.milliseconds.zeros(0))", terminator: " ")
        return bodies
    }
}
