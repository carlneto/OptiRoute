//
//  Chromosome.swift
//  OptiRoute
//
//  Created by Carlos Neto on 04/04/2020.
//  Copyright © 2020 Carlos Neto. All rights reserved.
//
import UIKit

class Chromosome {
    
    let cities: [City]
    
    private var _weight: Double?
    var weight: Double {
        if _weight == nil {
            _weight = calculateWeight()
        }
        return _weight ?? 0.0
    }
    
    init(cities: [City]) {
        self.cities = cities
    }
    
    private func calculateWeight() -> Double {
        var result: Double = 0.0
        var previousCity: City?
        cities.forEach { city in
            if let previous = previousCity {
                result += previous.weightTo(other: city)
            }
            previousCity = city
        }
        guard let first = cities.first, let last = cities.last else { return result }
        return result + first.weightTo(other: last)
    }
    
    var description: String {
        var ret = "["
        for city in cities {
            ret += city.name + ", "
        }
        return ret + "]"
    }
    
    // Probability of being selected from 0 to 1
    func fitness(withTotalWeight totalWeigh: Double) -> Double {
        return 1 - (weight / totalWeigh)
    }
}
/// Chromosome operators
extension Chromosome {
    
    func produceOffspring(secondParent: Chromosome) -> Chromosome {
        let firstParent = self
        let slice = Int(arc4random_uniform(UInt32(firstParent.cities.count)))
        var cities: [City] = Array<City>(firstParent.cities[0..<slice])
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
    
    func mutate(probability: Double) -> Chromosome {
        let child = self
        if probability >= Double(Double(arc4random()) / Double(UINT32_MAX)) {
            let firstIdx = Int(arc4random_uniform(UInt32(child.cities.count)))
            let secondIdx = Int(arc4random_uniform(UInt32(child.cities.count)))
            var cities = child.cities
            cities.swapAt(firstIdx, secondIdx)
            return Chromosome(cities: cities)
        }
        return child
    }
    
    func mutate(withOther parentTwo: Chromosome, probability percentage: Double) -> Chromosome {
        let child = produceOffspring(secondParent: parentTwo)
        let finalChild = child.mutate(probability: percentage)
        return finalChild
    }
}
