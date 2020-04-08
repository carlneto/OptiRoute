//
//  Population.swift
//  OptiRoute
//
//  Created by Carlos Neto on 04/04/2020.
//  Copyright © 2020 Carlos Neto. All rights reserved.
//
import UIKit

typealias Population = [Chromosome]

extension Population {
     
    var totalWeight: Double {
        return self.reduce(0.0, { $0 + $1.weight })
    }
    
    var vip: Chromosome? {
        return currentGeneration(totalWeight: totalWeight).first
    }
    
    var stats: (pop: Population, weight: Double, vip: Chromosome?) {
        let weight = totalWeight
        let actual = currentGeneration(totalWeight: weight)
        let first = actual.first
        return (actual, weight, first)
    }
    
    private func currentGeneration(totalWeight weight: Double) -> Population {
        let sortByFitnessDESC: (Chromosome, Chromosome) -> Bool = { $0.fitness(withTotalWeight: weight) > $1.fitness(withTotalWeight: weight) }
        let currentGeneration = sorted(by: sortByFitnessDESC)
        return currentGeneration
    }
    
    /// Population operators
    private func parent(with weightTotal: Double) -> Chromosome? {
        let fitness = Double(arc4random()) / Double(UINT32_MAX)
        var currentFitness: Double = 0.0
        var result: Chromosome?
        forEach { route in
            if currentFitness <= fitness {
                currentFitness += route.fitness(withTotalWeight: weightTotal) //TODO: This is using the 'elitist' method, convert it to a 'roulette'
                result = route
            }
        }
        return result
    }
    
    func child(mutation mutationProbability: Double, weight: Double) -> Chromosome? {
        if let parentOne = parent(with: weight), let parentTwo = parent(with: weight) {
            return parentOne.mutate(withOther: parentTwo, probability: mutationProbability)
        }
        return nil
    }
}
