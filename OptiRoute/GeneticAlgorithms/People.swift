import UIKit

typealias People = [Person]

extension People {
    
    var totalWeight: Double {
        return self.reduce(0.0, { $0 + $1.weight })
    }
    
    var vip: Person? {
        return currentGeneration(totalWeight: totalWeight).first
    }
    
    var stats: (pop: People, weight: Double, vip: Person?) {
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
    
    mutating func fillWith(organs: Body) {
        let bodies = [organs,
                      organs.sortFromFirst,
                      organs.sortFromBorders,
                      organs.sortFromFarestPair(hugging: false),
                      organs.sortFromFarestPair(hugging: true)
        ]
        for body in bodies {
            append(Person(body: body))
            for gen in body.generate(size: 2) {
                append(Person(body: gen))
                append(Person(body: gen.sortFromFirst))
                append(Person(body: gen.sortFromBorders))
                append(Person(body: gen.sortFromFarestPair(hugging: false)))
                append(Person(body: gen.sortFromFarestPair(hugging: true)))
            }
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
