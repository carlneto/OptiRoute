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
        let lim = Swift.min(12, Int(Double(self.body.count) * 0.4))
        DispatchQueue.global().async {
            var counter = 0
            while self.evolving {
                var nextGeneration = People()
                let stats = self.people.stats
                if let newBest = stats.vip {
                    if self.bestOne == nil {
                        self.bestOne = newBest
                        nextGeneration.fillWith(organs: self.body)
                        nextGeneration.fillWith(organs: newBest.body)
                    }
                    if let best = self.bestOne, newBest.weight < best.weight {
                        self.bestOne = newBest
                        //print(counter, terminator: ", ")
                        counter = 0
                    } else {
                        let barrier = 2
                        if counter > barrier {
                            nextGeneration.fillWith(organs: newBest.body)
                            if let bestBody = self.bestOne?.body {
                                nextGeneration.fillWith(organs: bestBody)
                            }
                            let randomSize = Swift.min(self.peopleSize / 3, (counter - barrier + 1) * self.peopleSize / 8)
                            nextGeneration += self.body.generatePeople(size: randomSize)
                        }
                        counter += 1
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
                guard counter > lim || self.benchTimer.elapsed > self.timeLimit else { continue }
                self.stopEvolution()
                guard let bestRoute = self.bestOne else { return }
                //self.onNewGeneration?(bestRoute, Int(bestRoute.weight))
                print("pop:\(self.peopleSize), counter: \(counter) > \(lim) || \(self.benchTimer.elapsed.zeros(1)) > \(self.timeLimit.zeros(1)), bestRoute \(bestRoute.weight.zeros(0))")
                self.onEvolutionEnd?(bestRoute, Int(bestRoute.weight))
            }
        }
    }
    
    public func stopEvolution() {
        evolving = false
    }
    
    private func setRandomPeople() {
        self.body = self.body.sortFromFarestPair(hugging: false)
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
        self.body = self.body.sortFromFarestPair(hugging: true)
    }
    
    private func randomPeople(fromOrgans: Body) -> People {
        var result = People()
        for _ in 0 ..< peopleSize {
            result.append(Person(body: fromOrgans.shuffle()))
        }
        return result
    }
}
