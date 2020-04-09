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
        let sortByFitnessDESC: (Person, Person) -> Bool = { $0.fitness(withTotalWeight: weight) > $1.fitness(withTotalWeight: weight) }
        let currentGeneration = sorted(by: sortByFitnessDESC)
        return currentGeneration
    }
    
    /// People operators
    private func parent(with weightTotal: Double) -> Person? {
        let fitness = Double(arc4random()) / Double(UINT32_MAX)
        var currentFitness: Double = 0.0
        var result: Person?
        forEach { route in
            if currentFitness <= fitness {
                currentFitness += route.fitness(withTotalWeight: weightTotal) //TODO: This is using the 'elitist' method, convert it to a 'roulette'
                result = route
            }
        }
        return result
    }
    
    func child(mutation mutationProbability: Double, weight: Double) -> Person? {
        if let parentOne = parent(with: weight), let parentTwo = parent(with: weight) {
            return parentOne.mutate(withOther: parentTwo, probability: mutationProbability)
        }
        return nil
    }
}
