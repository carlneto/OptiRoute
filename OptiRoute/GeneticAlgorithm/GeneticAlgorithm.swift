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
        timeLimit = Double(citiesCount)
        //populationSize = Swift.min(900, 2 * citiesCount * Int(timeLimit * 2))
        populationSize = Swift.min(citiesCount * 40, 2 * citiesCount * Int(timeLimit * 2))
        if let maxSize = citiesCount.factorial, maxSize < populationSize {
            populationSize = maxSize
        }
        maxGenerations = 10 + citiesCount / 2
        print("\ncountries \(populationSize) with \(citiesCount) cities, start generations: \(maxGenerations)")
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
        for i in 1...(4 - Swift.max(1, (self.cities.count + 1) / 8)) {
            let tmp = randomPopulation(fromCities: cities)
            let popTotalWeight = population.status.totalWeight
            let tmpTotalWeight = tmp.status.totalWeight
            guard tmpTotalWeight < popTotalWeight else { continue }
            print("i: \(i)\t\t\(Int(tmpTotalWeight)) <- \(Int(popTotalWeight))")
            population = tmp
        }
        DispatchQueue.global().async {
            var deltas = [Double]()
            var totalWeight: Double = 0
            let stepper = Swift.max(1, (self.cities.count + 1) / 8)
            while self.evolving {
                let actual = self.population.status
                let actualTotalWeight = Double(actual.totalWeight)
                if totalWeight > 0 {
                    let averageWeight = totalWeight / Double(self.generationCounter - 1)
                    let minimum = Swift.min(averageWeight, actualTotalWeight)
                    let maximum = Swift.max(averageWeight, actualTotalWeight)
                    let diff = maximum / minimum - 1
                    let delta = diff * diff * 1024
                    //print("#\(String(format: "%02d", self.generationCounter)) delta: \(String(format: "%.1f", delta))")
                    if delta < deltas.min() ?? 0 {
                        deltas.append(delta)
                        self.maxGenerations += stepper
                    }
                    if deltas.isEmpty {
                        deltas.append(delta)
                    }
                }
                totalWeight += actualTotalWeight
                var nextGeneration = Population()
                self.mutationProb = Swift.max(pow(1.1, -0.44 * Double(self.generationCounter)), 0.015)
                //print("mutationProb: \(self.mutationProb) at: \(self.generationCounter)")
                for _ in 0 ..< self.populationSize {
                    if let child = actual.population.child(mutation: self.mutationProb, weight: actual.totalWeight) {
                        nextGeneration.append(child)
                    }
                }
                self.population = nextGeneration
                if let bestRoute = self.population.bestIndividual {
                    self.onNewGeneration?(bestRoute, self.generationCounter)
                }
                self.generationCounter += 1
                guard self.benchTimer.elapsed > self.timeLimit ||
                    self.generationCounter > self.maxGenerations else { continue }
                print("\(String(format: "%.1f", self.benchTimer.elapsed)) > \(self.timeLimit) || \(self.generationCounter) > \(self.maxGenerations)")
                self.stopEvolution()
                guard let bestRoute = self.population.bestIndividual else { return }
                self.onNewGeneration?(bestRoute, Int(bestRoute.distance))
                print("Generation weight: \(String(format: "%.0f", bestRoute.distance))")
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
