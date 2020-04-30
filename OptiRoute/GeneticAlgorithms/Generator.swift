import UIKit

class Generator {
    
    var onNewGeneration: ( (Body, Int) -> () )?
    var onEvolutionEnd: ( (Body, Int, Bool) -> () )?
    
    private var ancestor: Person
    private var isCircle: Bool
    private var evolving = false
    
    init(organsNameContent: [String : Any], muscles: (_ body: Body, _ isLinear: Bool) -> Body, isCircle: Bool) {
        Organ.relax()
        self.isCircle = isCircle
        var body = Body()
        for organNameContent in organsNameContent {
            body.appendOrgan(name: organNameContent.key, content: organNameContent.value)
        }
        ancestor = Person(body: muscles(body, !self.isCircle))
    }
    
    private var randomBody: Body {
        let pos = Int(arc4random_uniform(UInt32(self.ancestor.body.count)))
        return self.ancestor.body.rotated(shift: pos).shuffled()
    }
    
    func startEvolution() {
        DispatchQueue.global().async {
            let t = BenchTimer()
            let bodyCount = self.ancestor.body.count
            let timeLimit = Swift.min(45.0, Double(bodyCount / 2))
            let timeMinimum = timeLimit / 6
            var peopleSize = Swift.min(512, 4 * bodyCount)
            var mutationProb = 0.50
            print("\npop:\(peopleSize) bodyCount:\(bodyCount) time:\(timeLimit.zeros(1))", terminator: " ")
            var people = People(from: self.ancestor.body, size: peopleSize)
            let buffer = 2
            var counter = buffer, genCount = 1
            var bestOne: Person?
            self.evolving = true
            while self.evolving {
                if counter == 1, t.elapsed < timeMinimum {
                    mutationProb = 0.68
                    peopleSize = Swift.max(bodyCount / 3, 100 * peopleSize / 110)
                    //=print("\n#\(peopleSize) i\(genCount) \(t.elapsed.zeros(3))", terminator: " ")
                    people = People(from: self.randomBody, size: peopleSize)
                    counter = buffer
                }
                let stats = people.stats()
                var nextGeneration = People()
                if let newBest = stats.vip {
                    nextGeneration.add(people: stats.pop, vip: newBest, size: peopleSize, isLast: counter == 0)
                    //print("(\(nextGeneration.count)", terminator: ">")
                    //nextGeneration.removeDuplicates()
                    //print(nextGeneration.count, terminator: ") ")
                    //print("(\(nextGeneration.count))", terminator: " ")
                    if bestOne == nil {
                        bestOne = newBest
                        self.onNewGeneration?(newBest.body, Int(newBest.weight + 0.5))
                    } else if let best = bestOne, newBest.weight < best.weight {
                        bestOne = newBest
                        counter = buffer
                        self.onNewGeneration?(newBest.body, Int(newBest.weight + 0.5))
                    } else {
                        let nPersons = Swift.min(peopleSize / 3, (buffer - counter + 1) * peopleSize / 8)
                        nextGeneration.addRandom(vip: newBest, size: nPersons, isLast: counter == 0)
                        counter -= 1
                    }
                }
                nextGeneration.addRoulette(people: stats.pop, size: peopleSize / 4, isLast: counter == -1)
                nextGeneration.addChildren(statistics: stats, probInitial: mutationProb,
                                           size: peopleSize, isLast: counter == -1)
                people = nextGeneration
                print("\(counter)", terminator: " ")
                genCount += 1
                guard counter < 0 || t.elapsed > timeLimit else { continue }
                self.evolving = false
                guard let bestRoute = bestOne else { return }
                print("\npop:\(peopleSize) bodyCount:\(bestRoute.body.count), counter: \(counter) | genCount: \(genCount) | \(t.elapsed.zeros(1)) > \(timeLimit.zeros(1)), bestRoute \(bestRoute.weight.zeros(0))")
                self.ended(person: bestRoute)
            }
        }
    }
    
    func stopEvolution() {
        evolving = false
    }
    
    func ended(person bestRoute: Person) {
        var vipBody = bestRoute.body
        if !isCircle {
            let count = vipBody.count
            var min = Double(Int.max)
            var idx = 0
            for i in 0 ..< count {
                let a = vipBody[i % count]
                let b = vipBody[(i + 1) % count]
                let c = Swift.min(a.muscleTo(other: b), b.muscleTo(other: a))
                if min > c {
                    min = c
                    idx = i
                }
            }
            vipBody.rotate(shift: idx + 1)
            if let first = vipBody.first, first.name == "0" {
                vipBody.reverse()
            }
        }
        self.onEvolutionEnd?(vipBody, Int(bestRoute.weight.rounded()), isCircle)
    }
}
