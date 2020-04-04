//
//  City.swift
//  OptiRoute
//
//  Created by Carlos Neto on 04/04/2020.
//  Copyright © 2020 Carlos Neto. All rights reserved.
//
import UIKit

struct City: Equatable {
    
    let location: CGPoint
    
    func distance(to: City) -> CGFloat {
        return sqrt(pow(to.location.x - self.location.x, 2) + pow(to.location.y - self.location.y, 2))
    }
    
    static func ==(lhs: City, rhs: City) -> Bool {
        return lhs.location == rhs.location
    }
}

struct Node: Fitness, Movable {
    
    typealias T = Node
    static var weights = [[Node]: Double]()
  
    let location: CGPoint
    let name: String
    var movable = true
    
    init(x: Double, y: Double, name: String, movable: Bool = true) {
        self.name = name
        self.location = CGPoint(x: x, y: y)
        self.movable = movable
    }
    
    func weight(other: Node) -> Double {
        if let aWeight = Node.weights[[self, other]] {
            return aWeight
        }
        if let aWeight = Node.weights[[other, self]] {
            return aWeight
        }
        let aWeight = hypot(Double(location.x - other.location.x), Double(location.y - other.location.y))
        Node.weights[[self, other]] = aWeight
        return aWeight
    }
    
    var description: String {
        return "x: \(location.x), y: \(location.y), name: \(name)"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(location.x)
        hasher.combine(location.y)
        hasher.combine(name)
    }
    
    static func < (lhs: Node, rhs: Node) -> Bool {
        return lhs.name < rhs.name
    }
    
    static func == (lhs: Node, rhs: Node) -> Bool {
        return lhs.location == rhs.location
    }
    
    static let nodes = [
        Node(x:  40.0, y:  70.0, name: "A", movable: false),
        Node(x: 240.0, y: 630.0, name: "N"),
        Node(x: 200.0, y: 140.0, name: "D"),
        Node(x: 330.0, y:  80.0, name: "F"),
        Node(x: 320.0, y: 700.0, name: "O"),
        Node(x: 380.0, y: 140.0, name: "G"),
        Node(x: 130.0, y: 180.0, name: "C"),
        Node(x:  70.0, y: 130.0, name: "B"),
        Node(x: 400.0, y: 210.0, name: "H"),
        Node(x: 200.0, y: 490.0, name: "L"),
        Node(x: 240.0, y: 420.0, name: "K"),
        Node(x: 360.0, y: 280.0, name: "I"),
        Node(x: 300.0, y: 350.0, name: "J"),
        Node(x: 180.0, y: 570.0, name: "M"),
        Node(x: 240.0, y:  80.0, name: "E"),
        Node(x: 400.0, y: 750.0, name: "P", movable: false)
    ]
}
