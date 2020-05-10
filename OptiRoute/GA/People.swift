import UIKit

typealias People = [Person]
extension People {
    
    var totalWeight: Double {
        return self.reduce(0.0, { $0 + $1.weight })
    }
    
    init(from body: Body, size: Int) {
        self.init()
        for b in body.sort() { self.append(Person(body: b)) }
        for person in self {
            for b in person.body.dispart() { self.append(Person(body: b)) }
        }
        for person in self {
            for b in person.body.untwist(interval: 5) { self.append(Person(body: b)) }
        }
        self.trim(size: 1 * size / 5)
        while self.count < size {
            self.append(Person(body: body.shuffled()))
        }
    }
    
    mutating func stats() -> (pop: People, weight: Double, vip: Person?) {
        let weight = self.totalWeight
        self = self.currentGeneration(totalWeight: weight)
        return (self, weight, self.first)
    }
    
    private func currentGeneration(totalWeight weight: Double) -> People {
        let sortByFitnessDESC: (Person, Person) -> Bool = { $0.fitnessProb(withTotalWeight: weight) > $1.fitnessProb(withTotalWeight: weight) }
        return sorted(by: sortByFitnessDESC)
    }
    
    /// Propagation
    
    mutating func add(vip: Person, size: Int, isLast: Bool) {
        guard !isLast else { return }
        var best: Body {
            let newStats = self.stats()
            if let newVip = newStats.vip {
                return newVip.body.rotated(shift: Int(arc4random_uniform(UInt32(vip.body.count / 3))))
            }
            return vip.body.reversed()
        }
        for b in best.dispart() { self.append(Person(body: b)) }
        for b in best.collect() { self.append(Person(body: b)) }
        for b in best.release() { self.append(Person(body: b)) }
        for person in self {
            for b in person.body.untwist(interval: 5) { self.append(Person(body: b)) }
        }
    }
    
    mutating func addRandom(vip: Person, size: Int, isLast: Bool) {
        guard !isLast else { return }
        self += vip.body.generatePeople(size: size)
    }
    
    mutating func addChildren(statistics: (pop: People, weight: Double, vip: Person?), prob: Double, size: Int, isLast: Bool) {
        guard !isLast else { return }
        self.removeDuplicates()
        var mutationProb = prob
        repeat {
            if let child = statistics.pop.elitistChild(mutation: mutationProb, weight: statistics.weight) { self.append(child) }
            if mutationProb == prob, count >= size {
                mutationProb = 0.997
                self.removeDuplicates()
            }
        } while self.count < size
    }
    
    mutating func removeDuplicates() {
        self = People(Set(self))
    }
    
    mutating func trim(size: Int) {
        self.removeDuplicates()
        let pop = self.stats().pop
        self = People(pop[0..<Swift.min(pop.count, size)])
    }
    
    /// People operators
    
    func elitistChild(mutation mutationProbability: Double, weight: Double) -> Person? {
        if let parentOne = self.elitistParent(with: weight), let parentTwo = self.elitistParent(with: weight) {
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
    
    func randomSelection() -> (index: Int, body: Body) {
        let index = Int(arc4random_uniform(UInt32(self.count)))
        return (index, self[index])
    }
}
