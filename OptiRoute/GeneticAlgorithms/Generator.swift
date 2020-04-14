import UIKit

class Generator {
    
    var timeLimit = 0.0
    let benchTimer = BenchTimer()
    var onNewGeneration: ( (Person, Int) -> () )?
    var onEvolutionEnd: ( (Person, Int) -> () )?
    
    private(set) var bestOne: Person?
    private var body: Body
    private var organs: Body?
    private var people = People()
    private var evolving = false
    private var peopleSize = 0
    private var generationCounter = 1
    
    init(subject: Body) {
        body = subject
        let bodyCount = body.count
        timeLimit = Double(bodyCount)
        peopleSize = Swift.min(512, 40 * bodyCount)
        if let maxSize = bodyCount.factorial, maxSize < peopleSize {
            peopleSize = maxSize
        }
    }
    
    func sort() {
        var edges = body.sortedWeights()
        var organs = [Organ]()
        guard let item = edges.first else { return }
        var leftOrgan = item.o1
        var rightOrgan = item.o2
        organs.append(leftOrgan)
        organs.append(rightOrgan)
        edges.removeFirst()
        func add(_ aOrgan: Organ) {
            if !organs.contains(aOrgan) { organs.append(aOrgan) }
        }
        func leftAdd(_ aOrgan: Organ) {
            leftOrgan = aOrgan
            add(leftOrgan)
        }
        func rightAdd(_ aOrgan: Organ) {
            rightOrgan = aOrgan
            add(rightOrgan)
        }
        while organs.count < body.count {
            for i in 0 ..< edges.count {
                let edge = edges[i]
                var toRemove = false
                if leftOrgan == edge.o1 {
                    leftAdd(edge.o2)
                    toRemove = true
                } else if leftOrgan == edge.o2 {
                    leftAdd(edge.o1)
                    toRemove = true
                }
                if rightOrgan == edge.o1 {
                    rightAdd(edge.o2)
                    toRemove = true
                } else if rightOrgan == edge.o2 {
                    rightAdd(edge.o1)
                    toRemove = true
                }
                if toRemove {
                    edges.remove(at: i)
                    break
                }
            }
        }
        body = organs
    }
    
    func startEvolution() {
        print("\npop:\(peopleSize) bodyCount:\(body.count) time:\(timeLimit.zeros(1))")
        evolving = true
        benchTimer.restart()
        sort()
        let lim = self.body.count / 2
        let itrs = Swift.max(1, 4 - Swift.max(1, (body.count + 1) / 8))
        func setPeople() {
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
        setPeople()
        DispatchQueue.global().async {
            var counter = 0
            while self.evolving {
                var nextGeneration = People()
                let stats = self.people.stats
                if let newBest = stats.vip {
                    if self.bestOne == nil {
                        self.bestOne = newBest
                    }
                    if let best = self.bestOne, newBest.weight < best.weight {
                        self.bestOne = newBest
                        counter = 0
                    } else {
                        if counter > 3 {
                            let randomSize = Swift.min(self.peopleSize / 2, (counter - 3) * self.peopleSize / 8)
                            nextGeneration += self.body.generatePeople(size: randomSize)
                            //nextGeneration.append(Person(body: self.body))
                            //self.body.rotate(positions: 1)
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
                nextGeneration = Array(Set(nextGeneration))
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
                print("\npop:\(self.peopleSize), counter: \(counter) > \(lim) || \(self.benchTimer.elapsed.zeros(1)) > \(self.timeLimit.zeros(1)), bestRoute \(bestRoute.weight.zeros(0))")
                self.onEvolutionEnd?(bestRoute, Int(bestRoute.weight))
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
