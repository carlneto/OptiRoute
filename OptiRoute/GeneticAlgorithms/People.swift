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
    
    /// People operators
    private func elitistParent(with weightTotal: Double) -> Person? {
        let fitness = Double(arc4random()) / Double(UINT32_MAX)
        var currentFitness: Double = 0.0
        var result: Person?
        forEach { body in //TODO: This is using the 'elitist' method, convert it to a 'roulette'
            if currentFitness <= fitness {
                //currentFitness += body.fitnessProb(withTotalWeight: weightTotal)
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
    
//    func tournament(size: Int = 4) -> People {
//        var people = self
//        var matingPeople = People()
//        repeat {
//            var fighters = [Int: Person]()
//            var highestFighterIndex = 0
//            var highestFighterFitness = 0.0
//            repeat {
//                let idx = Int(arc4random_uniform(UInt32(people.count)))
//                let person = people[idx]
//                fighters[idx] = person
//                let fitness = person.weight
//                if fitness > highestFighterFitness {
//                    highestFighterFitness = fitness
//                    highestFighterIndex = idx
//                }
//            } while fighters.count < size
//            if let highestFighter = fighters[highestFighterIndex] {
//                matingPeople.append(highestFighter)
//                people.remove(at: highestFighterIndex)
//            }
//        } while matingPeople.count < count / 2
//        return matingPeople
//    }
}
