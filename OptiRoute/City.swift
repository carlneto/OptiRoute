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
    
    var description: String {
        return "(\(Int(location.x)),\(Int(location.y))),"
    }
    
    static func ==(lhs: City, rhs: City) -> Bool {
        return lhs.location == rhs.location
    }
}

struct Node: Fitness, Movable {
    
    typealias T = Node
    static let wFactor = Double(UIScreen.main.bounds.width / 450)
    static let hFactor = Double(UIScreen.main.bounds.height / 900)
    static var weights = [[Node]: Double]()
  
    let location: CGPoint
    let name: String
    var movable = true
    
    init(x: Double, y: Double, name: String, movable: Bool = true, sample: Bool = false) {
        self.name = name
        self.location = CGPoint(x: sample ? x*Node.wFactor : x, y: sample ? y*Node.hFactor-30 : y)
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
        Node(x:  40.0, y:  70.0, name: "A", movable: false, sample: true),
        Node(x: 240.0, y: 630.0, name: "N", sample: true),
        Node(x: 200.0, y: 140.0, name: "D", sample: true),
        Node(x: 330.0, y:  80.0, name: "F", sample: true),
        Node(x: 320.0, y: 700.0, name: "O", sample: true),
        Node(x: 380.0, y: 140.0, name: "G", sample: true),
        Node(x: 130.0, y: 180.0, name: "C", sample: true),
        Node(x:  70.0, y: 130.0, name: "B", sample: true),
        Node(x: 400.0, y: 210.0, name: "H", sample: true),
        Node(x: 200.0, y: 490.0, name: "L", sample: true),
        Node(x: 240.0, y: 420.0, name: "K", sample: true),
        Node(x: 360.0, y: 280.0, name: "I", sample: true),
        Node(x: 300.0, y: 350.0, name: "J", sample: true),
        Node(x: 180.0, y: 570.0, name: "M", sample: true),
        Node(x: 240.0, y:  80.0, name: "E", sample: true),
        Node(x: 400.0, y: 750.0, name: "P", movable: false, sample: true)
    ]
}
