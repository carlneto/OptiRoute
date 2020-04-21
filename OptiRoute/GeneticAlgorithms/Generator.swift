import UIKit

class Generator {
    
    var onNewGeneration: ( (Person, Int) -> () )?
    var onEvolutionEnd: ( (Person, Int) -> () )?
    
    private var body: Body
    private var evolving = false
    
    init(subject: Body) {
        body = subject
    }
    
    func startEvolution() {
        DispatchQueue.global().async {
            let benchTimer = BenchTimer()
            let bodyCount = self.body.count
            let timeLimit = Swift.min(30.0, Double(bodyCount / 2))
            let peopleSize = Swift.min(512, 40 * bodyCount)
            var people = self.randomPeople(fromOrgans: self.body, size: peopleSize)
            print("\npop:\(peopleSize) bodyCount:\(bodyCount) time:\(timeLimit.zeros(1))")
            let buffer = 3
            var counter = buffer, genCount = 1
            var bestOne: Person?
            self.evolving = true
            while self.evolving {
                let stats = people.stats()
                var nextGeneration = People()
                if let newBest = stats.vip {
                    nextGeneration.addFrom(people: stats.pop, genCount: genCount)
                    print("(\(nextGeneration.count)", terminator: ">")
                    nextGeneration.removeDuplicates()
                    print(nextGeneration.count, terminator: ") ")
                    //print("(\(nextGeneration.count)", terminator: ") ")
                    if bestOne == nil {
                        bestOne = newBest
                    } else if let best = bestOne, newBest.weight < best.weight {
                        bestOne = newBest
                        counter = buffer
                    } else {
                        let randomSize = Swift.min(peopleSize / 3, (buffer - counter + 1) * peopleSize / 8)
                        nextGeneration += newBest.body.generatePeople(size: randomSize)
                        counter -= 1
                    }
                    let aBest = bestOne ?? newBest
                    self.onNewGeneration?(aBest, Int(aBest.weight + 0.5))
                }
                for _ in 0 ..< peopleSize / 4 {
                    if let roulette = stats.pop.roulette {
                        nextGeneration.append(roulette.person)
                    }
                }
                nextGeneration.removeDuplicates()
                //print(nextGeneration.count, terminator: ") ")
                var mutationProb = 0.68
                repeat {
                    if let child = stats.pop.child(mutation: mutationProb, weight: stats.weight) {
                        nextGeneration.append(child)
                    }
                    if mutationProb == 0.68, nextGeneration.count >= peopleSize {
                        mutationProb = 0.95
                        nextGeneration.removeDuplicates()
                    }
                } while nextGeneration.count < peopleSize
                people = nextGeneration
                print("\(counter)", terminator: " ")
                genCount += 1
                guard counter < 0 || benchTimer.elapsed > timeLimit else { continue }
                self.evolving = false
                guard let bestRoute = bestOne else { return }
                print("\npop:\(peopleSize) bodyCount:\(bestRoute.body.count), counter: \(counter) | genCount: \(genCount) | \(benchTimer.elapsed.zeros(1)) > \(timeLimit.zeros(1)), bestRoute \(bestRoute.weight.zeros(0))")
                self.onEvolutionEnd?(bestRoute, Int(bestRoute.weight))
            }
        }
    }
    
    func stopEvolution() {
        evolving = false
    }
    
    private func randomPeople(fromOrgans: Body, size: Int) -> People {
        var result = People()
        result.initWith(body: fromOrgans, size: size)
        while result.count < size {
            result.append(Person(body: fromOrgans.shuffle()))
        }
        return result
    }
}
