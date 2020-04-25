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
            let peopleSize = Swift.min(512, 6 * bodyCount)
            print("\npop:\(peopleSize) bodyCount:\(bodyCount) time:\(timeLimit.zeros(1))")
            var people = People(from: self.body, size: peopleSize)
            let buffer = 2
            var counter = buffer, genCount = 1
            var bestOne: Person?
            self.evolving = true
            while self.evolving {
                let stats = people.stats()
                var nextGeneration = People()
                if let newBest = stats.vip {
                    nextGeneration.addSpecial(people: stats.pop, vip: newBest, isLast: counter == 0)
                    //print("(\(nextGeneration.count)", terminator: ">")
                    //nextGeneration.removeDuplicates()
                    //print(nextGeneration.count, terminator: ") ")
                    //print("(\(nextGeneration.count))", terminator: " ")
                    if bestOne == nil {
                        bestOne = newBest
                        self.onNewGeneration?(newBest, Int(newBest.weight + 0.5))
                    } else if let best = bestOne, newBest.weight < best.weight {
                        bestOne = newBest
                        counter = buffer
                        self.onNewGeneration?(newBest, Int(newBest.weight + 0.5))
                    } else {
                        let nPersons = Swift.min(peopleSize / 3, (buffer - counter + 1) * peopleSize / 8)
                        nextGeneration.addRandom(vip: newBest, size: nPersons, isLast: counter == 0)
                        counter -= 1
                    }
                }
                nextGeneration.addRoulette(people: stats.pop, size: peopleSize / 4, isLast: counter == -1)
                nextGeneration.addChildren(statistics: stats, size: peopleSize, isLast: counter == -1)
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
}
