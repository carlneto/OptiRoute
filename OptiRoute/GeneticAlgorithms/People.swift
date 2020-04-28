import UIKit

typealias People = [Person]
extension People {
    
    var totalWeight: Double {
        return self.reduce(0.0, { $0 + $1.weight })
    }
    
    init(from body: Body, size: Int) {
        self.init()
        for sorted in body.sort() { self.append(Person(body: sorted)) }
        self.add(people: self, vip: Person(body: body), size: size, isLast: false)
        print("\ninit: \(count)")
        while !self.isEmpty, self.count < size / 2 {
            if let child = self.child(mutation: 0.68, weight: stats().weight) { self.append(child) }
        }
        //=print("\nv\(self.stats().vip!.weight.zeros(0))\ninitWith: \(count)")
        while self.count < size {
            self.append(Person(body: body.shuffle()))
        }
    }
    
    mutating func stats() -> (pop: People, weight: Double, vip: Person?) {
        let weight = self.totalWeight
        let actual = self.currentGeneration(totalWeight: weight)
        let first = actual.first
        return (actual, weight, first)
    }
    
    private func currentGeneration(totalWeight weight: Double) -> People {
        let sortByFitnessDESC: (Person, Person) -> Bool = { $0.fitnessProb(withTotalWeight: weight) > $1.fitnessProb(withTotalWeight: weight) }
        let currentGeneration = sorted(by: sortByFitnessDESC)
        return currentGeneration
    }
    
    /// Popularization
    
    mutating func add(people: People, vip: Person, size: Int, isLast: Bool) {
        guard !isLast else { return }
        var best: Body {
            let newStats = self.stats()
            if let newVip = newStats.vip {
                return newVip.body.rotated(shift: Int(arc4random_uniform(UInt32(vip.body.count / 3))))
            }
            return vip.body.reversed()
        }
        for uncross in best.uncross() { self.append(Person(body: uncross)) }
        for collect in best.collect() { self.append(Person(body: collect)) }
        for ejected in best.ejected() { self.append(Person(body: ejected)) }
        //for untwist in best.untwists() { self.append(Person(body: untwist)) }
        for person in self {
            for untwist in person.body.untwists(interval: 5) { self.append(Person(body: untwist)) }
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
                self.append(roulette.person)
            }
        }
    }
    
    mutating func addChildren(statistics: (pop: People, weight: Double, vip: Person?), size: Int, isLast: Bool) {
        guard !isLast else { return }
        self.removeDuplicates()
        let probInitial = 0.68
        var mutationProb = probInitial
        repeat {
            if let child = statistics.pop.child(mutation: mutationProb, weight: statistics.weight) {
                self.append(child)
            }
            if mutationProb == probInitial, count >= size {
                mutationProb = 0.32
                self.removeDuplicates()
            }
        } while self.count < size
    }
    
    mutating func removeDuplicates() {
        self = Array(Set(self))
    }
    
    /// People operators
    
    func child(mutation mutationProbability: Double, weight: Double) -> Person? {
        if let parentOne = self.elitistParent(with: weight), let parentTwo = elitistParent(with: weight) {
            return parentOne.mutate(withOther: parentTwo, probability: mutationProbability)
        }
        return nil
    }
    
    private func elitistParent(with weightTotal: Double) -> Person? {
        let fitness = Double(arc4random()) / Double(UINT32_MAX)
        var currentFitness: Double = 0.0
        var result: Person?
        self.forEach { body in
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
        self.forEach { body in
            let result = body.calculateWeight()
            weight = Swift.min(weight, result)
        }
        return weight
    }
}
