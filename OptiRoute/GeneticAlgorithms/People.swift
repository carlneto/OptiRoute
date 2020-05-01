import UIKit

typealias People = [Person]
extension People {
    
    var totalWeight: Double {
        return self.reduce(0.0, { $0 + $1.weight })
    }
    
    init(from body: Body, size: Int) {
        self.init()
        for b in body.sort() { self.append(Person(body: b)) }
        for person in self {
            for b in person.body.uncross() { self.append(Person(body: b)) }
        }
        for person in self {
            for b in person.body.untwists(interval: 5) { self.append(Person(body: b)) }
        }
        self.trim(size: 1 * size / 5)
        while self.count < size {
            self.append(Person(body: body.shuffled()))
        }
        //print("\ni \(count) best \(self.stats().vip!.weight.zeros(0))")
    }
    
    mutating func stats() -> (pop: People, weight: Double, vip: Person?) {
        let weight = self.totalWeight
        self = self.currentGeneration(totalWeight: weight)
        return (self, weight, self.first)
    }
    
    private func currentGeneration(totalWeight weight: Double) -> People {
        let sortByFitnessDESC: (Person, Person) -> Bool = { $0.fitnessProb(withTotalWeight: weight) > $1.fitnessProb(withTotalWeight: weight) }
        return sorted(by: sortByFitnessDESC)
    }
    
    /// Propagation
    
    mutating func add(vip: Person, size: Int, isLast: Bool) {
        guard !isLast else { return }
        var best: Body {
            let newStats = self.stats()
            if let newVip = newStats.vip {
                return newVip.body.rotated(shift: Int(arc4random_uniform(UInt32(vip.body.count / 3))))
            }
            return vip.body.reversed()
        }
        for b in best.uncross() { self.append(Person(body: b)) }
        for b in best.collect() { self.append(Person(body: b)) }
        for b in best.release() { self.append(Person(body: b)) }
        for person in self {
            for b in person.body.untwists(interval: 5) { self.append(Person(body: b)) }
        }
    }
    
    mutating func addRandom(vip: Person, size: Int, isLast: Bool) {
        guard !isLast else { return }
        self += vip.body.generatePeople(size: size)
    }
    
    mutating func addChildren(statistics: (pop: People, weight: Double, vip: Person?),
                              prob: Double, size: Int, isLast: Bool) {
        guard !isLast else { return }
        self.removeDuplicates()
        var mutationProb = prob
        repeat {
            if Int.random(in: 0...3) < 3 {
                if let child = statistics.pop.elitistChild(mutation: mutationProb, weight: statistics.weight) { self.append(child) }
            } else {
                if let child = statistics.pop.rouletteChild(mutation: 0.05, weight: statistics.weight) { self.append(child) }
            }
            if mutationProb == prob, count >= size {
                mutationProb = 0.997
                self.removeDuplicates()
            }
        } while self.count < size
    }
    
    mutating func removeDuplicates() {
        self = People(Set(self))
    }
    
    mutating func trim(size: Int) {
        self.removeDuplicates()
        let pop = self.stats().pop
        self = People(pop[0..<Swift.min(pop.count, size)])
    }
    
    /// People operators
    
    func elitistChild(mutation mutationProbability: Double, weight: Double) -> Person? {
        if let parentOne = self.elitistParent(with: weight), let parentTwo = self.elitistParent(with: weight) {
            return parentOne.mutate(withOther: parentTwo, probability: mutationProbability)
        }
        return nil
    }
    
    private func elitistParent(with weightTotal: Double) -> Person? {
        let fitness = Double(arc4random()) / Double(UINT32_MAX)
        var currentFitness: Double = 0.0
        var result: Person?
        self.forEach { body in
            if currentFitness <= fitness {
                currentFitness += (1 - body.weight / weightTotal)
                result = body
            }
        }
        return result
    }
    
    func rouletteChild(mutation mutationProbability: Double, weight: Double) -> Person? {
        guard let parentOne = self.roulette(), var parentTwo = self.roulette() else { return nil }
        for _ in 0 ..< self.count {
            guard parentTwo.index == parentOne.index else { break }
            parentTwo = roulette() ?? parentOne
        }
        guard parentTwo.index != parentOne.index else { return nil }
        return parentOne.person.mutate(withOther: parentTwo.person, probability: mutationProbability)
    }
    
    private func roulette() -> (index: Int, person: Person)? {
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
    
    func swapChilddren(mutationRate: Double, size: Int) -> People {
        let matingPeople = self.tournament(size: size, selectionSize: Swift.min(4, size / 2))
        guard matingPeople.count > 1 else { return matingPeople }
        var children = matingPeople.crossover(allowDuplicates: false)
        for childIndex in 0 ..< children.count {
            for i in 0 ..< children[childIndex].count {
                guard (Double(arc4random_uniform(UInt32(10e5))) / 10e5) <= mutationRate else { continue }
                let child = children[childIndex]
                let genA = child[i]
                var genB: Organ
                var j: Int
                repeat {
                    j = Int(arc4random_uniform(UInt32(child.count)))
                    genB = child[j]
                } while j == i
                children[childIndex][i] = genB
                children[childIndex][j] = genA
            }
        }
        //=print("\nchildren: \(children.count)")
        return children.compactMap { return Person(body: $0) }
    }
    
    private func tournament(size: Int, selectionSize: Int) -> People {
        let t = BenchTimer()
        let matingPoolSize = Swift.min(self.count / 2, Swift.max(2, size))
        var pool = self
        var matingPool = Set<Person>()
        repeat {
            var fighters = [Int: Person]()
            var bestIdx = 0
            var bestFitness = 0.0
            repeat {
                guard t.elapsed < 0.500 else { return People(matingPool) }
                let random = pool.randomSelection()
                fighters[random.index] = random.person
                if random.person.weight > bestFitness {
                    bestFitness = random.person.weight
                    bestIdx = random.index
                }
            } while fighters.count < selectionSize
            if let best = fighters[bestIdx] {
                if matingPool.insert(best).inserted {
                    pool.remove(at: bestIdx)
                }
            }
        } while matingPool.count < matingPoolSize
        return People(matingPool)
    }
    
    private func crossover(allowDuplicates: Bool) -> Bodies {
        var firstParents = self
        var children = Bodies()
        let total = self.count * 2
        while children.count < total {
            let parentA = firstParents.remove(at: Int(arc4random_uniform(UInt32(firstParents.count))))
            let parentB = firstParents.remove(at: Int(arc4random_uniform(UInt32(firstParents.count))))
            if firstParents.count < 2 {
                firstParents = self
            }
            let childs = performCrossover(chromosomeA: parentA.body, chromosomeB: parentB.body)
            var childA = childs.childA
            var childB = childs.childB
            if !allowDuplicates {
                swapDuplicates(genesA: &childA, &childB)
            }
            children.append(childA)
            children.append(childB)
        }
        return children
    }
    
    private func performCrossover(chromosomeA: Body, chromosomeB: Body) -> (childA: Body, childB: Body) {
        let point1 = Int(arc4random_uniform(UInt32(chromosomeA.count)))
        let point2 = Int(arc4random_uniform(UInt32(chromosomeB.count)))
        let crossoverA = Swift.min(point1, point2)
        var childGenesA = Body()
        var childGenesB = Body()
        for i in 0 ..< chromosomeA.count {
            if i < crossoverA {
                childGenesA.append(chromosomeA[i])
                childGenesB.append(chromosomeB[i])
            } else {
                childGenesA.append(chromosomeB[i])
                childGenesB.append(chromosomeA[i])
            }
        }
        return (childA: childGenesA, childB: childGenesB)
    }
    
    private func swapDuplicates( genesA: inout Body, _ genesB: inout Body) {
        var duplicatesA: [Organ : Int] = duplicatesForGenes(genes: genesA)
        var duplicatesB: [Organ : Int] = duplicatesForGenes(genes: genesB)
        while duplicatesA.count > 0 {
            guard let a = duplicatesA.popFirst(),let b = duplicatesB.popFirst() else { continue }
            genesA[a.1] = b.0
            genesB[b.1] = a.0
        }
    }
    
    private func duplicatesForGenes(genes: Body) -> [Organ: Int] {
        var set = Set<Organ>()
        var duplicates: [Organ : Int] = [:]
        var index = 0
        for gene in genes {
            if set.contains(gene) {
                duplicates[gene] = index
            } else {
                set.insert(gene)
            }
            index += 1
        }
        return duplicates
    }
    
    private func randomSelection() -> (index: Int, person: Person) {
        let index = Int(arc4random_uniform(UInt32(self.count)))
        return (index, self[index])
    }
}

typealias Bodies = [Body]
extension Bodies {
    
    func best() -> Double {
        var weight = Double(Int.max)
        self.forEach { body in
            let result = body.calculateWeight()
            weight = Swift.min(weight, result)
        }
        return weight
    }
}
