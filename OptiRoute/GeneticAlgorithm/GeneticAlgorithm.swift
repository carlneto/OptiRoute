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
    let mutationProb = 0.5
    let timeLimit = 5.0
    let cities: [City]
    let benchTimer = BenchTimer()
    var onNewGeneration: ( (Chromosome, Int) -> () )?
    
    private var population = Population()
    private var evolving = false
    private var generationCounter = 1
    
    init(withCities: [City]) {
        self.cities = withCities
        self.populationSize = Int(timeLimit * 2) * cities.count * 2
        print("populationSize: \(populationSize)")
        self.population = self.randomPopulation(fromCities: self.cities)
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
        for i in 1...3 {
            let tmp = self.randomPopulation(fromCities: self.cities)
            let popTotalWeight = population.status.totalWeight
            let tmpTotalWeight = tmp.status.totalWeight
            guard tmpTotalWeight < popTotalWeight else { continue }
            print("i: \(i)")
            population = tmp
        }
        DispatchQueue.global().async {
            while self.evolving {
                let actual = self.population.status
                var nextGeneration = Population()
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
                if self.benchTimer.elapsed > self.timeLimit, self.generationCounter > 50 {
                    self.stopEvolution()
                    if let bestRoute = self.population.bestIndividual {
                        self.onNewGeneration?(bestRoute, Int(bestRoute.distance))
                    }
                }
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

public class BenchTimer {
    
    var startTime = CFAbsoluteTimeGetCurrent()
    
    public var elapsed: CFAbsoluteTime {
        return CFAbsoluteTimeGetCurrent() - startTime
    }
    
    public func restart() {
        startTime = CFAbsoluteTimeGetCurrent()
    }
}
