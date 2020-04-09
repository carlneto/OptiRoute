import UIKit

class Generator {
    
    var timeLimit = 0.0
    let body: Body
    let benchTimer = BenchTimer()
    var onNewGeneration: ( (Person, Int) -> () )?
    var evolving = false
    
    private(set) var bestOne: Person?
    private var people = People()
    private var peopleSize = 0
    private var generationCounter = 1
    private var maxGenerations = 0
    private var incrementProb = 0
    private var bestGeneration = 0
    
    init(subject: Body) {
        body = subject
        let bodyCount = body.count
        timeLimit = Double(bodyCount) * 1.5
        peopleSize = Swift.min(512, bodyCount * 40, 2 * bodyCount * Int(timeLimit * 2))
        if let maxSize = bodyCount.factorial, maxSize < peopleSize {
            peopleSize = maxSize
        }
        maxGenerations = bodyCount / 2
        people = randomPeople(fromOrgans: body)
    }
    
    public func startEvolution() {
        print("\npop:\(peopleSize) bodyCount:\(body.count) it:\(maxGenerations) time:\(timeLimit.zeros(1))")
        bestOne = nil
        evolving = true
        benchTimer.restart()
        let itrs = Swift.max(1, 4 - Swift.max(1, (self.body.count + 1) / 8))
        for _ in 1...itrs {
            let tmp = randomPeople(fromOrgans: body)
            let popTotalWeight = people.stats.weight
            let tmpTotalWeight = tmp.stats.weight
            guard tmpTotalWeight < popTotalWeight else { continue }
            //print("i: \(i)\t\t\(Int(tmpTotalWeight)) <- \(Int(popTotalWeight))")
            people = tmp
        }
        DispatchQueue.global().async {
            var counter = -1
            while self.evolving {
                let stats = self.people.stats
                if let newBest = stats.vip {
                    if self.bestOne == nil {
                        self.bestOne = newBest
                    }
                    if let best = self.bestOne, newBest.weight < best.weight {
                        self.bestOne = newBest
                        self.maxGenerations += 2
                        self.bestGeneration = self.generationCounter
                    } else {
                        counter += 1
                    }
                    self.onNewGeneration?(self.bestOne ?? newBest, self.generationCounter)
                }
                if counter > 2 {
                    counter = 0
                    self.incrementProb = self.generationCounter - 1
                    if let best = self.bestOne {
                        if self.generationCounter - self.bestGeneration > 9 {
                            self.bestGeneration = self.generationCounter
                        } else {
                            let halfMin = 2 * self.body.count
                            self.peopleSize = (halfMin + Int(arc4random_uniform(UInt32(512 - halfMin)))) * 2
                            //print("#\(self.generationCounter)\tpop:\(self.peopleSize)")
                            self.people = self.randomPeople(fromOrgans: self.body)
                            self.people[0] = best
                        }
                    }
                }
                var nextGeneration = People()
                let mutationProb = Swift.max(pow(1.1, -0.44 * Double(self.generationCounter - self.incrementProb)), 0.015)
                for _ in 0 ..< self.peopleSize {
                    if let child = stats.pop.child(mutation: mutationProb, weight: stats.weight) {
                        nextGeneration.append(child)
                    }
                }
                self.people = nextGeneration
                self.generationCounter += 1
                guard self.benchTimer.elapsed > self.timeLimit || self.generationCounter > self.maxGenerations else { continue }
                self.stopEvolution()
                guard let bestRoute = self.bestOne else { return }
                self.onNewGeneration?(bestRoute, Int(bestRoute.weight))
                print("pop:\(self.peopleSize), \(self.benchTimer.elapsed.zeros(1)) > \(self.timeLimit.zeros(1)) || \(self.generationCounter) > \(self.maxGenerations), bestRoute \(bestRoute.weight.zeros(0))")
            }
        }
    }
    
    public func stopEvolution() {
        evolving = false
    }
    
    private func randomPeople(fromOrgans: Body) -> People {
        var result = People()
        for _ in 0 ..< peopleSize {
            result.append(Person(body: fromOrgans.shuffle()))
        }
        return result
    }
}
