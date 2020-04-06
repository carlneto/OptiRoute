//
//  BenchTimer.swift
//  OptiRoute
//
//  Created by Carlos Neto on 05/04/2020.
//  Copyright © 2020 Carlos Neto. All rights reserved.
//
import Foundation

public class BenchTimer {
    
    var startTime = CFAbsoluteTimeGetCurrent()
    
    public var elapsed: CFAbsoluteTime {
        return CFAbsoluteTimeGetCurrent() - startTime
    }
    
    public func restart() {
        startTime = CFAbsoluteTimeGetCurrent()
    }
}
