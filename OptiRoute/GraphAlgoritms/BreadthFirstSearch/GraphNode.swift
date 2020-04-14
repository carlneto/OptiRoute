#if os(Linux)
import Glibc
#else
import Darwin
#endif

class GraphNode: CustomStringConvertible, Equatable {
    
    var neighbors: [Connection]
    
    private(set) var name: String
    let x: Double
    let y: Double
    
    var distance: Double?
    var visited: Bool
    
    init(x: Double, y: Double, name: String) {
        self.x = x
        self.y = y
        self.name = name
        neighbors = []
        visited = false
    }
    
    var description: String {
        if let distance = distance {
            return "GraphNode(name: \(name), distance: \(distance))"
        }
        return "GraphNode(name: \(name), distance: infinity)"
    }
    
    var hasDistance: Bool {
        return distance != nil
    }
    
    func remove(_ connection: Connection) {
        neighbors.remove(at: neighbors.firstIndex { $0 === connection }!)
    }
    
    static func == (_ lhs: GraphNode, rhs: GraphNode) -> Bool {
        return lhs.name == rhs.name && lhs.neighbors == rhs.neighbors
    }
    
    func weight(other: GraphNode) -> Double {
        return hypot(Double(x - other.x), Double(y - other.y))
    }
    
    var originWeight: Double {
        return weight(other: GraphNode(x: 0, y: 0, name: ""))
    }
    
    var toString: String {
        return "x: \(x), y: \(y), name: \(name)"
    }
    
    static func < (lhs: GraphNode, rhs: GraphNode) -> Bool {
        return lhs.name < rhs.name
    }
}
