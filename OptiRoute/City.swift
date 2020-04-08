//
//  City.swift
//  OptiRoute
//
//  Created by Carlos Neto on 04/04/2020.
//  Copyright © 2020 Carlos Neto. All rights reserved.
//
import UIKit

//struct City: Equatable {
//
//    let location: CGPoint
//
//    func weight(to: City) -> CGFloat {
//        return sqrt(pow(to.location.x - self.location.x, 2) + pow(to.location.y - self.location.y, 2))
//    }
//
//    var description: String {
//        return "(\(Int(location.x)),\(Int(location.y))),"
//    }
//
//    static func ==(lhs: City, rhs: City) -> Bool {
//        return lhs.location == rhs.location
//    }
//}

struct City: Fitness, Movable {
    
    typealias T = City
    static let wFactor = Double(UIScreen.main.bounds.width / 450)
    static let hFactor = Double(UIScreen.main.bounds.height / 900)
    static var weights = [[City]: Double]()
    static var mean: Double?
  
    let location: CGPoint
    let name: String
    var movable = true
    
    init(location: CGPoint, name: String? = nil, movable: Bool = true) {
        self.init(x: Double(location.x), y:  Double(location.y), name: name ?? "(\(Int(location.x)),\(Int(location.y)))", movable: movable)
    }
    
    init(x: Double, y: Double, name: String, movable: Bool = true, sample: Bool = false) {
        self.name = name
        self.location = CGPoint(x: sample ? x*City.wFactor : x, y: sample ? y*City.hFactor-30 : y)
        self.movable = movable
    }
    
    func weightTo(other: City) -> Double {
        if let aWeight = City.weights[[other, self]] {
            return aWeight
        }
        if let aWeight = City.weights[[self, other]] {
            return aWeight
        }
//        if !movable, !other.movable {
//            print(name + " -> " + other.name)
//            City.weights[[self, other]] = 0
//            return 0
//        }
        let aWeight = hypot(Double(location.x - other.location.x), Double(location.y - other.location.y))
        City.weights[[self, other]] = aWeight
        return aWeight
    }
    
    var description: String {
        return "name: \(name), x: \(Int(location.x)), y: \(Int(location.y))"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(location.x)
        hasher.combine(location.y)
        hasher.combine(name)
    }
    
    static func < (lhs: City, rhs: City) -> Bool {
//        return lhs.location.x + lhs.location.y < rhs.location.x + rhs.location.y
        let dist = lhs.weightTo(other: rhs)
        if City.mean == nil {
            var sum = 0.0
            for w in City.weights {
                sum += w.value
            }
            City.mean = sum / Double(City.weights.count)
        }
        return dist < (City.mean ?? 0)
    }
    
    static func == (lhs: City, rhs: City) -> Bool {
        return lhs.location == rhs.location
    }
    
    static let nodes = [
        City(x:  40.0, y:  70.0, name: "A", movable: false, sample: true),
        City(x: 240.0, y: 630.0, name: "N", sample: true),
        City(x: 200.0, y: 140.0, name: "D", sample: true),
        City(x: 330.0, y:  80.0, name: "F", sample: true),
        City(x: 320.0, y: 700.0, name: "O", sample: true),
        City(x: 380.0, y: 140.0, name: "G", sample: true),
        City(x: 130.0, y: 180.0, name: "C", sample: true),
        City(x:  70.0, y: 130.0, name: "B", sample: true),
        City(x: 400.0, y: 210.0, name: "H", sample: true),
        City(x: 200.0, y: 490.0, name: "L", sample: true),
        City(x: 240.0, y: 420.0, name: "K", sample: true),
        City(x: 360.0, y: 280.0, name: "I", sample: true),
        City(x: 300.0, y: 350.0, name: "J", sample: true),
        City(x: 180.0, y: 570.0, name: "M", sample: true),
        City(x: 240.0, y:  80.0, name: "E", sample: true),
        City(x: 400.0, y: 750.0, name: "P", movable: false, sample: true)
    ]
}

typealias Cities = [City]

extension Cities {
    
    func prt() {
        var ret = "["
        for city in self {
            ret += " \(city.location.x.str(0)) \(city.location.y.str(0)) \(city.name) |"
        }
        print(ret + "]")
    }
}
