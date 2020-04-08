//
//  GeneticAlgorithm.swift
//  OptiRoute
//
//  Created by Carlos Neto on 04/04/2020.
//  Copyright © 2020 Carlos Neto. All rights reserved.
//
import UIKit

class GeneticAlgorithm {
    
    var bestOne: Chromosome?
    var populationSize = 0
    var timeLimit = 0.0
    let cities: [City]
    let benchTimer = BenchTimer()
    var onNewGeneration: ( (Chromosome, Int) -> () )?
    var evolving = false
    
    private var population = Population()
    private var generationCounter = 1
    private var maxGenerations = 0
    private var incrementProb = 0
    private var bestGeneration = 0
    
    init(withCities: [City]) {
        cities = withCities
        let citiesCount = cities.count
        timeLimit = Double(citiesCount) * 1.5
        populationSize = Swift.min(512, citiesCount * 40, 2 * citiesCount * Int(timeLimit * 2))
        if let maxSize = citiesCount.factorial, maxSize < populationSize {
            populationSize = maxSize
        }
        maxGenerations = citiesCount / 2
        print("\npop:\(populationSize) city:\(citiesCount) it:\(maxGenerations) time:\(timeLimit.str(1))")
        population = randomPopulation(fromCities: cities)
    }
    
    private func randomPopulation(fromCities: [City]) -> Population {
        var result = Population()
        for _ in 0 ..< populationSize {
            result.append(Chromosome(cities: fromCities.shuffle()))
        }
        return result
    }
    
    public func startEvolution() {
        bestOne = nil
        evolving = true
        benchTimer.restart()
        let itrs = Swift.max(1, 4 - Swift.max(1, (self.cities.count + 1) / 8))
        for _ in 1...itrs {
            let tmp = randomPopulation(fromCities: cities)
            let popTotalWeight = population.stats.weight
            let tmpTotalWeight = tmp.stats.weight
            guard tmpTotalWeight < popTotalWeight else { continue }
            //print("i: \(i)\t\t\(Int(tmpTotalWeight)) <- \(Int(popTotalWeight))")
            population = tmp
        }
        let bcts = self.cities
        let count = bcts.count
        if count > 20  {
            for i in 0..<3 {
                let citiesGrupped = bcts.shuffle().chunk(min: Swift.min(9, Swift.max(6, count / 3)))
                var genetics = [GeneticAlgorithm]()
                for cityGroup in citiesGrupped {
                    let ga = GeneticAlgorithm(withCities: cityGroup)
                    ga.timeLimit = 2
                    ga.startEvolution()
                    genetics.append(ga)
                }
                var running = true
                while running {
                    running = genetics.reduce(true, { $0 && $1.evolving })
                }
                var newVips = [City]()
                for ga in genetics {
                    guard let gaRoute = ga.bestOne else { continue }
                    self.onNewGeneration?(gaRoute, self.generationCounter)
                    sleep(1)
                    newVips += gaRoute.cities
                }
                if newVips.count == self.cities.count {
                    let chromo = Chromosome(cities: newVips)
                    //                                self.onNewGeneration?(chromo, Int(chromo.weight))
                    self.population[i] = chromo
                }
            }
        }
        DispatchQueue.global().async {
            var counter = -1
            while self.evolving {
                let stats = self.population.stats
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
                            //                            var bcts = self.cities
                            //                            let count = bcts.count
                            //                            guard count > 18 else { continue }
                            //                            var idx = 0
                            //                            var ws: Double?
                            //                            for i in 0..<count {
                            //                                let w = bcts[i % count].weightTo(other: bcts[(i + 1) % count])
                            //                                if w < ws ?? Double(Int.max) {
                            //                                    ws = w
                            //                                    idx = (i + 1) % count
                            //                                }
                            //                            }
                            //                            bcts.rotate(positions: idx)
                            //                            let citiesGrupped = bcts.chunk(min: Swift.min(9, Swift.max(6, count / 3)))
                            //                            var genetics = [GeneticAlgorithm]()
                            //                            for cityGroup in citiesGrupped {
                            //                                let ga = GeneticAlgorithm(withCities: cityGroup)
                            //                                ga.timeLimit = 2
                            //                                ga.startEvolution()
                            //                                genetics.append(ga)
                            //                            }
                            //                            var running = true
                            //                            while running {
                            //                                running = genetics.reduce(true, { $0 && $1.evolving })
                            //                            }
                            //                            var newVips = [City]()
                            //                            for ga in genetics {
                            //                                guard let gaRoute = ga.bestOne else { continue }
                            //                                self.onNewGeneration?(gaRoute, self.generationCounter)
                            //                                sleep(1)
                            //                                newVips += gaRoute.cities
                            //                            }
                            //                            if newVips.count == self.cities.count {
                            //                                let chromo = Chromosome(cities: newVips)
                            ////                                self.onNewGeneration?(chromo, Int(chromo.weight))
                            //                                self.population[1] = chromo
                            //                            }
                        } else {
                            let halfMin = 2 * self.cities.count
                            self.populationSize = (halfMin + Int(arc4random_uniform(UInt32(512 - halfMin)))) * 2
                            //print("#\(self.generationCounter)\tpop:\(self.populationSize)")
                            self.population = self.randomPopulation(fromCities: self.cities)
                            self.population[0] = best
                        }
                    }
                }
                var nextGeneration = Population()
                let mutationProb = Swift.max(pow(1.1, -0.44 * Double(self.generationCounter - self.incrementProb)), 0.015)
                for _ in 0 ..< self.populationSize {
                    if let child = stats.pop.child(mutation: mutationProb, weight: stats.weight) {
                        nextGeneration.append(child)
                    }
                }
                self.population = nextGeneration
                self.generationCounter += 1
                guard self.benchTimer.elapsed > self.timeLimit || self.generationCounter > self.maxGenerations else { continue }
                self.stopEvolution()
                guard let bestRoute = self.bestOne else { return }
                self.onNewGeneration?(bestRoute, Int(bestRoute.weight))
                print("pop:\(self.populationSize), \(self.benchTimer.elapsed.str(1)) > \(self.timeLimit.str(1)) || \(self.generationCounter) > \(self.maxGenerations), bestRoute \(bestRoute.weight.str(0))")
            }
        }
    }
    
    public func stopEvolution() {
        evolving = false
    }
}

extension Array {
    public func shuffle() -> [Element] {
        return sorted(by: { (_, _) -> Bool in
            return arc4random() < arc4random()
        })
    }
}

public extension Int {
    var factDouble: Double {
        return (1...self).map(Double.init).reduce(1.0, *)
    }
    var factorial: Int? {
        guard factDouble < Double(Int.max) else { return nil }
        return Int(factDouble)
    }
}

extension Double {
    func str(_ decimals: Int) -> String {
        return String(format: "%.\(decimals)f", self)
    }
}

extension CGFloat {
    func str(_ decimals: Int) -> String {
        return String(format: "%.\(decimals)f", self)
    }
}

extension Collection where Element: Numeric {
    /// Returns the total sum of all elements in the array
    var total: Element { reduce(0, +) }
}

extension Collection where Element: BinaryInteger {
    /// Returns the average of all elements in the array
    var average: Double { isEmpty ? 0 : Double(total) / Double(count) }
}

extension Collection where Element: BinaryFloatingPoint {
    /// Returns the average of all elements in the array
    var average: Element { isEmpty ? 0 : total / Element(count) }
}

extension Array {
    var splitted: (left: [Element], right: [Element]) {
        let ct = self.count
        let half = ct / 2
        let leftSplit = self[0 ..< half]
        let rightSplit = self[half ..< ct]
        return (left: Array(leftSplit), right: Array(rightSplit))
    }
    func chunk(min size: Int) -> [[Element]] {
        var arr = chunk(max: size)
        if let last = arr.last, last.count < size {
            arr[0] += last
            arr.removeLast()
        }
        return arr
    }
    func chunk(max size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
