//
//  GeneticAlgorithm.swift
//  OptiRoute
//
//  Created by Carlos Neto on 04/04/2020.
//  Copyright © 2020 Carlos Neto. All rights reserved.
//
import UIKit

class GeneticAlgorithm {
    
    var populationSize = 0
    var mutationProb = 1.0
    var timeLimit = 0.0
    let cities: [City]
    let benchTimer = BenchTimer()
    var onNewGeneration: ( (Chromosome, Int) -> () )?
    
    private var population = Population()
    private var evolving = false
    private var generationCounter = 1
    private var maxGenerations = 0
    
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
            let randomCities = fromCities.shuffle()
            result.append(Chromosome(cities: randomCities))
        }
        return result
    }
    
    public func startEvolution() {
        evolving = true
        benchTimer.restart()
        let itrs = (4 - Swift.max(1, (self.cities.count + 1) / 8))
        for i in 1...itrs {
            let tmp = randomPopulation(fromCities: cities)
            let popTotalWeight = population.stats.weight
            let tmpTotalWeight = tmp.stats.weight
            guard tmpTotalWeight < popTotalWeight else { continue }
            //print("i: \(i)\t\t\(Int(tmpTotalWeight)) <- \(Int(popTotalWeight))")
            population = tmp
        }
        DispatchQueue.global().async {
            var bestOne: Chromosome?
            var counter = -1
            while self.evolving {
                let stats = self.population.stats
                if let newBest = stats.vip {
                    if bestOne == nil {
                        bestOne = newBest
                    }
                    if let best = bestOne, newBest.distance < best.distance {
                        bestOne = newBest
                        self.maxGenerations += 2
                    } else {
                        counter += 1
                    }
                    self.onNewGeneration?(bestOne ?? newBest, self.generationCounter)
                }
                if counter > 2 {
                    counter = 0
                    self.populationSize = Int.random(in: (2 * self.cities.count)...512) * 2
                    //print("#\(self.generationCounter)\tpop:\(self.populationSize)")
                    self.population = self.randomPopulation(fromCities: self.cities)
                    if let best = bestOne {
                        self.population[0] = best
                    }
                }
                self.mutationProb = Swift.max(pow(1.1, -0.44 * Double(self.generationCounter)), 0.015)
                var nextGeneration = Population()
                for _ in 0 ..< self.populationSize {
                    if let child = stats.pop.child(mutation: self.mutationProb, weight: stats.weight) {
                        nextGeneration.append(child)
                    }
                }
                self.population = nextGeneration
                self.generationCounter += 1
                guard self.benchTimer.elapsed > self.timeLimit || self.generationCounter > self.maxGenerations else { continue }
                self.stopEvolution()
                guard let bestRoute = bestOne else { return }
                self.onNewGeneration?(bestRoute, Int(bestRoute.distance))
                print("pop:\(self.populationSize), \(self.benchTimer.elapsed.str(1)) > \(self.timeLimit.str(1)) || \(self.generationCounter) > \(self.maxGenerations), bestRoute \(bestRoute.distance.str(0))")
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
