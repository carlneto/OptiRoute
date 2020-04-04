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
    
    private var _distance: CGFloat?
    var distance: CGFloat {
        if _distance == nil {
            _distance = calculateDistance()
        }
        return _distance ?? 0.0
    }
    
    init(cities: [City]) {
        self.cities = cities
    }
    
    private func calculateDistance() -> CGFloat {
        var result: CGFloat = 0.0
        var previousCity: City?
        cities.forEach { city in
            if let previous = previousCity {
                result += previous.distance(to: city)
            }
            previousCity = city
        }
        guard let first = cities.first, let last = cities.last else { return result }
        return result + first.distance(to: last)
    }
    
    var description: String {
        var ret = "["
        for city in cities {
            ret += city.description
        }
        return ret + "]"
    }
    
    // Probability of being selected from 0 to 1
    func fitness(withTotalDistance totalDistance: CGFloat) -> CGFloat {
        return 1 - (distance / totalDistance)
    }
}
/// Chromosome operators
extension Chromosome {
    
    func produceOffspring(secondParent: Chromosome) -> Chromosome {
        let firstParent = self
        let slice: Int = Int(arc4random_uniform(UInt32(firstParent.cities.count)))
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
