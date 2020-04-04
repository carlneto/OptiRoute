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
     
    var totalWeight: CGFloat {
        return self.reduce(0.0, { $0 + $1.distance })
    }
    
    var bestIndividual: Chromosome? {
        return currentGeneration(totalWeight: totalWeight).first
    }
    
    var status: (population: Population, totalWeight: CGFloat) {
        let weight = totalWeight
        return (currentGeneration(totalWeight: weight), weight)
    }
    
    private func currentGeneration(totalWeight weight: CGFloat) -> Population {
        let sortByFitnessDESC: (Chromosome, Chromosome) -> Bool = { $0.fitness(withTotalDistance: weight) > $1.fitness(withTotalDistance: weight) }
        let currentGeneration = sorted(by: sortByFitnessDESC)
        return currentGeneration
    }
    
    /// Population operators
    private func parent(with totalDistance: CGFloat) -> Chromosome? {
        let fitness = CGFloat(Double(arc4random()) / Double(UINT32_MAX))
        var currentFitness: CGFloat = 0.0
        var result: Chromosome?
        forEach { route in
            if currentFitness <= fitness {
                currentFitness += route.fitness(withTotalDistance: totalDistance) //TODO: This is using the 'elitist' method, convert it to a 'roulette'
                result = route
            }
        }
        return result
    }
    
    func child(mutation mutationProbability: Double, weight: CGFloat) -> Chromosome? {
        if let parentOne = parent(with: weight), let parentTwo = parent(with: weight) {
            return parentOne.mutate(withOther: parentTwo, probability: mutationProbability)
        }
        return nil
    }
}
