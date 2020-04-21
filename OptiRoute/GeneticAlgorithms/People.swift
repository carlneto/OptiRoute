import UIKit

typealias People = [Person]
extension People {
    
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
        for sorted  in body.sortedAll() { append(Person(body: sorted))  }
        for uncross in best.distorted() { append(Person(body: uncross)) }
        for smooth  in best.flattened()  { append(Person(body: smooth))  }
        let fitness = stats().weight
        let part = size / 2
        while count < part {
            if let child = child(mutation: 0.68, weight: fitness) {
                append(child)
            }
        }
    }
    
    mutating func addFrom(people: People, genCount: Int) {
        var siblings = Swift.min(people.count, 3)
        let part = Swift.max(2, people.count / 2 / siblings)
        for (idx, person) in people.enumerated() {
            guard siblings > 0 else { break }
            guard idx % part == 0 else { continue }
            append(Person(body: person.body))
            let body = genCount % 3 == 0 ? person.body : person.body.reversed()
            if genCount % 7 == 1 {
                for smooth in body.flattened(peaksRate: 0.10, neighborsCount: 3) { append(Person(body: smooth)) }
            } else {
                for uncross in body.distorted() { append(Person(body: uncross)) }
            }
//            for uncross in body.distorted(weakestRate: 0.05, nearsCount: 3) {
//                //append(Person(body: uncross))
//                for smooth in uncross.flattened(peaksRate: 0.02, neighborsCount: 1) {
//                    append(Person(body: smooth))
//                }
//            }
            siblings -= 1
        }
    }
    
    mutating func removeDuplicates() {
        self = Array(Set(self))
    }
    
    /// People operators
    
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
    
    func child(mutation mutationProbability: Double, weight: Double) -> Person? {
        if let parentOne = elitistParent(with: weight), let parentTwo = elitistParent(with: weight) {
            return parentOne.mutate(withOther: parentTwo, probability: mutationProbability)
        }
        return nil
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
