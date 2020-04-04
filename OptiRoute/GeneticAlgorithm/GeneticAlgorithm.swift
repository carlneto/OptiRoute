//
//  GeneticAlgorithm.swift
//  OptiRoute
//
//  Created by Carlos Neto on 04/04/2020.
//  Copyright © 2020 Carlos Neto. All rights reserved.
//
import UIKit

class GeneticAlgorithm {
    
    var populationSize = 250
    let mutationProbability = 0.02
    let timeLimit = 10.0
    let cities: [City]
    let benchTimer = BenchTimer()
    var onNewGeneration: ((Chromosome, Int) -> ())?
    
    private var population: Chromosomes = []
    private var evolving = false
    private var generationCounter = 1
    
    init(withCities: [City]) {
        self.cities = withCities
        self.population = self.randomPopulation(fromCities: self.cities)
    }
    
    private func randomPopulation(fromCities: [City]) -> Chromosomes {
        var result: Chromosomes = []
        for _ in 0 ..< populationSize {
            let randomCities = fromCities.shuffle()
            result.append(Chromosome(cities: randomCities))
        }
        return result
    }
    
    public func startEvolution() {
        evolving = true
        benchTimer.restart()
        DispatchQueue.global().async {
            while self.evolving {
                let currentTotalDistance = self.population.reduce(0.0, { $0 + $1.distance })
                let sortByFitnessDESC: (Chromosome, Chromosome) -> Bool = { $0.fitness(withTotalDistance: currentTotalDistance) > $1.fitness(withTotalDistance: currentTotalDistance) }
                let currentGeneration = self.population.sorted(by: sortByFitnessDESC)
                var nextGeneration: Chromosomes = []
                for _ in 0 ..< self.populationSize {
                    guard
                        let parentOne = self.getParent(fromGeneration: currentGeneration, withTotalDistance: currentTotalDistance),
                        let parentTwo = self.getParent(fromGeneration: currentGeneration, withTotalDistance: currentTotalDistance)
                        else { continue }
                    
                    let child = self.produceOffspring(firstParent: parentOne, secondParent: parentTwo)
                    let finalChild = self.mutate(child: child)
                    
                    nextGeneration.append(finalChild)
                }
                self.population = nextGeneration
                if let bestRoute = self.population.sorted(by: sortByFitnessDESC).first {
                    self.onNewGeneration?(bestRoute, self.generationCounter)
                }
                self.generationCounter += 1
                if self.benchTimer.elapsed > self.timeLimit {
                    self.stopEvolution()
                }
            }
        }
    }
    
    public func stopEvolution() {
        evolving = false
    }
    
    private func getParent(fromGeneration generation: Chromosomes, withTotalDistance totalDistance: CGFloat) -> Chromosome? {
        let fitness = CGFloat(Double(arc4random()) / Double(UINT32_MAX))
        var currentFitness: CGFloat = 0.0
        var result: Chromosome?
        generation.forEach { (route) in
            if currentFitness <= fitness {
                currentFitness += route.fitness(withTotalDistance: totalDistance) //TODO: This is using the 'elitist' method, convert it to a 'roulette'
                result = route
            }
        }
        return result
    }
    
    private func produceOffspring(firstParent: Chromosome, secondParent: Chromosome) -> Chromosome {
        let slice: Int = Int(arc4random_uniform(UInt32(firstParent.cities.count)))
        var cities: [City] = Array(firstParent.cities[0..<slice])
        var idx = slice
        while cities.count < secondParent.cities.count {
            let city = secondParent.cities[idx]
            if cities.contains(city) == false {
                cities.append(city)
            }
            idx = (idx + 1) % secondParent.cities.count
        }
        return Chromosome(cities: cities)
    }
    
    private func mutate(child: Chromosome) -> Chromosome {
        if self.mutationProbability >= Double(Double(arc4random()) / Double(UINT32_MAX)) {
            let firstIdx = Int(arc4random_uniform(UInt32(child.cities.count)))
            let secondIdx = Int(arc4random_uniform(UInt32(child.cities.count)))
            var cities = child.cities
            cities.swapAt(firstIdx, secondIdx)
            return Chromosome(cities: cities)
        }
        return child
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
