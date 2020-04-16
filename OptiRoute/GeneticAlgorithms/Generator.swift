import UIKit

class Generator {
    
    var timeLimit = 0.0
    let benchTimer = BenchTimer()
    var onNewGeneration: ( (Person, Int) -> () )?
    var onEvolutionEnd: ( (Person, Int) -> () )?
    
    private(set) var bestOne: Person?
    private var body: Body
    private var people = People()
    private var evolving = false
    private var peopleSize = 0
    private var generationCounter = 1
    
    init(subject: Body) {
        body = subject
        let bodyCount = body.count
        timeLimit = Swift.min(30.0, Double(bodyCount / 2))
        peopleSize = Swift.min(512, 40 * bodyCount)
        if let maxSize = bodyCount.factorial, maxSize < peopleSize {
            peopleSize = maxSize
        }
    }
    
    func startEvolution() {
        print("\npop:\(peopleSize) bodyCount:\(body.count) time:\(timeLimit.zeros(1))")
        evolving = true
        benchTimer.restart()
        setRandomPeople()
        DispatchQueue.global().async {
            let k = 9
            let barrier = k - 2
            var counter = k
            while self.evolving {
                var nextGeneration = People()
                let stats = self.people.stats
                if let newBest = stats.vip {
                    if self.bestOne == nil {
                        self.bestOne = newBest
                        nextGeneration.fillWith(organs: self.body)
                    }
                    if let best = self.bestOne, newBest.weight < best.weight {
                        self.bestOne = newBest
                        nextGeneration.fillWith(organs: newBest.body)
                        counter = k
                    } else {
                        if counter < barrier {
                            nextGeneration.fillWith(organs: newBest.body)
                            let randomSize = Swift.min(self.peopleSize / 3, (barrier - counter) * self.peopleSize / 8)
                            nextGeneration += newBest.body.generatePeople(size: randomSize)
                        }
                        counter -= 1
                    }
                    self.onNewGeneration?(self.bestOne ?? newBest, self.generationCounter)
                }
                for _ in 0 ..< self.peopleSize / 4 {
                    if let roulette = stats.pop.roulette {
                        nextGeneration.append(roulette.person)
                    }
                }
                nextGeneration.removeDuplicates()
                let mutationProb = Swift.max(pow(1.1, -0.44 * Double(self.generationCounter)), 0.015)
                while nextGeneration.count < self.peopleSize {
                    if let child = stats.pop.child(mutation: mutationProb, weight: stats.weight) {
                        nextGeneration.append(child)
                    }
                }
                self.people = nextGeneration
                self.generationCounter += 1
                guard counter < 0 || self.benchTimer.elapsed > self.timeLimit else { continue }
                self.stopEvolution()
                guard let bestRoute = self.bestOne else { return }
                print("pop:\(self.peopleSize) bodyCount:\(bestRoute.body.count), counter: \(counter) || \(self.benchTimer.elapsed.zeros(1)) > \(self.timeLimit.zeros(1)), bestRoute \(bestRoute.weight.zeros(0))")
                self.onEvolutionEnd?(bestRoute, Int(bestRoute.weight))
            }
        }
    }
    
    public func stopEvolution() {
        evolving = false
    }
    
    private func setRandomPeople() {
        let itrs = Swift.max(1, 4 - Swift.max(1, (body.count + 1) / 8))
        people = randomPeople(fromOrgans: body)
        for i in 1...itrs {
            let tmp = randomPeople(fromOrgans: body)
            let popTotalWeight = people.stats.weight
            let tmpTotalWeight = tmp.stats.weight
            guard tmpTotalWeight < popTotalWeight else { continue }
            print("i: \(i)\t\t\(Int(tmpTotalWeight)) <- \(Int(popTotalWeight))")
            people = tmp
        }
    }
    
    private func randomPeople(fromOrgans: Body) -> People {
        var result = People()
        for _ in 0 ..< peopleSize {
            result.append(Person(body: fromOrgans.shuffle()))
        }
        return result
    }
}
