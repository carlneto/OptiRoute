//
//  Gene.swift
//  OptiRoute
//
//  Created by Carlos Neto on 04/04/2020.
//  Copyright © 2020 Carlos Neto. All rights reserved.
//
import Foundation

protocol Fitness: Comparable {
    associatedtype T
    func weight(other: T) -> Double
}

public protocol Movable: Hashable {
    var movable: Bool { get set }
}

public struct Gene<T: Movable> : Hashable {
    
    public let value: T
    
    public init(value: T) {
        self.value = value
    }
}

public func ==<T: Movable> (lhs: Gene<T>, rhs: Gene<T>) -> Bool {
    return lhs.value == rhs.value
}
