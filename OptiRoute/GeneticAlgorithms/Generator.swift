import UIKit

class Generator {
    
    var onNewGeneration: ( (Body, Int) -> () )?
    var onEvolutionEnd: ( (Body, Int, Bool) -> () )?
    
    private var ancestor: Person
    private var isCircle: Bool
    private var evolving = Atomic<Int>(0)
    private var president: Atomic<Person>
    
    init?(organsNameContent: [String : Any], muscles: (_ body: Body, _ isLinear: Bool) -> Body, isCircle: Bool) {
        guard organsNameContent.count > 2 else { return nil }
        Organ.relax()
        self.isCircle = isCircle
        var body = Body()
        for organNameContent in organsNameContent {
            body.appendOrgan(name: organNameContent.key, content: organNameContent.value)
        }
        ancestor = Person(body: muscles(body, !self.isCircle))
        president = Atomic<Person>(ancestor)
    }
    
    private var randomBody: Body {
        let pos = Int(arc4random_uniform(UInt32(self.ancestor.body.count / 5)))
        return self.ancestor.body.rotated(shift: pos).shuffled()
    }
    
    func startEvolution() {
        let t = BenchTimer()
        let bodyCount = self.ancestor.body.count
        guard bodyCount > 2 else { return }
        let timeLimit = Swift.min(45.0, Double(bodyCount / 2))
        let timeMinimum = timeLimit / 6
        let peopleSize = Swift.min(512, 4 * bodyCount)
        let turns = president.value.turns
        evolving.value = turns
        //print("\npop \(peopleSize) r\(turns) bodyCount:\(bodyCount) t\(timeLimit.zeros(1)) ... ", terminator: " ")
        for i in 1...turns {
            DispatchQueue.global().async {
                var people = People(from: self.randomBody, size: peopleSize)
                let buffer = 2
                var counter = buffer, genCount = 1
                var bestOne = self.ancestor
                while self.evolving.value > 0 {
                    if counter == 1, t.elapsed < timeMinimum {
                        people = People(from: self.randomBody, size: peopleSize)
                        counter = buffer
                    }
                    let stats = people.stats()
                    var nextGeneration = People()
                    if let newBest = stats.vip {
                        nextGeneration.add(vip: newBest, size: peopleSize, isLast: counter == 0)
                        if newBest.weight < bestOne.weight {
                            if newBest.weight < self.president.value.weight {
                                self.president.value = newBest
                                if self.evolving.value > 0 {
                                    self.onNewGeneration?(newBest.body, Int(newBest.weight.rounded()))
                                }
                            }
                            bestOne = newBest
                            counter = buffer
                        } else {
                            let nPersons = Swift.min(peopleSize / 3, (buffer - counter + 1) * peopleSize / 8)
                            nextGeneration.addRandom(vip: newBest, size: nPersons, isLast: counter == 0)
                            counter -= 1
                        }
                    }
                    nextGeneration.addChildren(statistics: stats, prob: 0.68, size: peopleSize, isLast: counter == -1)
                    people = nextGeneration
                    genCount += 1
                    guard counter < 0 || t.elapsed > timeLimit else { continue }
                    guard self.evolving.decreased == 0 else { break }
                    print("\npop \(peopleSize) i\(i)_\(turns) bodyCount \(self.president.value.body.count) genCount \(genCount) t\(t.elapsed.zeros(1))_\(timeLimit.zeros(1)) bestRoute \(self.president.value.weight.zeros(0))")
                    sleep(1)
                    self.ended(person: self.president.value)
                }
            }
        }
    }
    
    func stopEvolution() {
        evolving.value = 0
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
