import UIKit

typealias People = [Person]
extension People {
    
    init(from body: Body, size: Int) {
        self.init()
        initWith(body: body, size: size)
        while count < size {
            append(Person(body: body.shuffle()))
        }
    }
    
    var totalWeight: Double {
        return self.reduce(0.0, { $0 + $1.weight })
    }
    
    func stats() -> (pop: People, weight: Double, vip: Person?) {
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
    
    mutating func initWith(body: Body, size: Int) {
        var best: Body { return stats().vip?.body ?? body }
        for sorted in body.sortedAll() { append(Person(body: sorted)) }
        for flatted in best.flatted(maximum: maxCount) { append(Person(body: flatted)) }
        for uncross in best.uncrossed(maximum: maxCount, nearsMax: tries) { append(Person(body: uncross)) }
        for swapForward in best.swapForwards(maximum: maxCount) { append(Person(body: swapForward)) }
        for flatten in best.flattened(maximum: maxCount, perPeak: tries) { append(Person(body: flatten)) }
        for straighted in best.straighted(maximum: maxCount) { append(Person(body: straighted)) }
        let fitness = stats().weight
        while count < size / 2 {
            if let child = child(mutation: 0.68, weight: fitness) {
                append(child)
            }
        }
        //print("\ninitWith: \(count)")
    }
    
    var maxCount: Double { return 0.25 }
    var tries: Int { return 8 }
    
    mutating func addSpecial(people: People, vip: Person, isLast: Bool) {
        guard !isLast else { return }
        for _ in 1 ... 2 {
            var best: Body {
                return self.stats().vip?.body ?? vip.body
            }
            for uncross in best.uncrossed(maximum: maxCount, nearsMax: tries) { append(Person(body: uncross)) }
            for swapForward in best.swapForwards(maximum: maxCount) { append(Person(body: swapForward)) }
            for straighted in best.straighted(maximum: maxCount) { append(Person(body: straighted)) }
            for flatted in best.flatted(maximum: maxCount) { append(Person(body: flatted)) }
            for flatten in best.flattened(maximum: maxCount, perPeak: tries) { append(Person(body: flatten)) }
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
