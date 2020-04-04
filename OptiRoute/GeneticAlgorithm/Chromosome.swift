//
//  Chromosome.swift
//  OptiRoute
//
//  Created by Carlos Neto on 04/04/2020.
//  Copyright © 2020 Carlos Neto. All rights reserved.
//
import UIKit

typealias Chromosomes = [Chromosome]

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
    // Probability of being selected from 0 to 1
    func fitness(withTotalDistance totalDistance: CGFloat) -> CGFloat {
        return 1 - (distance / totalDistance)
    }
}
