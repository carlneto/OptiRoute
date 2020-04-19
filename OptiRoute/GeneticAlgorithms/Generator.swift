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
            let buffer = 12
            let barrier = buffer - 2
            var counter = buffer
            var genCount = 1
            var fill = 0
            var bestOne: Person?
            self.evolving = true
            while self.evolving {
                var nextGeneration = People()
                let stats = people.stats()
                if let newBest = stats.vip {
                    if bestOne == nil {
                        bestOne = newBest
                        nextGeneration.fillWith(body: newBest.body)
                    } else if let best = bestOne, newBest.weight < best.weight {
                        bestOne = newBest
                        counter = buffer
                        fill = 0
                    } else {
                        fill += 1
                        if counter > 0, fill > 2 {
                            fill = 0
                            nextGeneration.fillFrom(people: stats.pop)
                        }
                        let randomSize = Swift.min(peopleSize / 3, (buffer - counter + 1) * peopleSize / 8)
                        nextGeneration += newBest.body.generatePeople(size: randomSize)
                        counter -= 1
                    }
                    self.onNewGeneration?(bestOne ?? newBest, genCount)
                }
                for _ in 0 ..< peopleSize / 4 {
                    if let roulette = stats.pop.roulette {
                        nextGeneration.append(roulette.person)
                    }
                }
                nextGeneration.removeDuplicates()
                let mutationProb = Swift.max(pow(1.1, -0.44 * Double(barrier - counter + 1)), 0.015)
                while nextGeneration.count < peopleSize {
                    if let child = stats.pop.child(mutation: mutationProb, weight: stats.weight) {
                        nextGeneration.append(child)
                    }
                }
                people = nextGeneration
                print("\(counter)", terminator: " ")
                genCount += 1
                guard counter < 0 || benchTimer.elapsed > timeLimit else { continue }
                self.evolving = false
                guard let bestRoute = bestOne else { return }
                print("\npop:\(peopleSize) bodyCount:\(bestRoute.body.count), counter: \(counter) | iters: \(genCount) | \(benchTimer.elapsed.zeros(1)) > \(timeLimit.zeros(1)), bestRoute \(bestRoute.weight.zeros(0))")
                self.onEvolutionEnd?(bestRoute, Int(bestRoute.weight))
            }
        }
    }
    
    func stopEvolution() {
        evolving = false
    }
    
    private func randomPeople(fromOrgans: Body, size: Int) -> People {
        var result = People()
        for _ in 0 ..< size {
            result.append(Person(body: fromOrgans.shuffle()))
        }
        return result
    }
}
