class Connection: Equatable {
    
    var neighbor: GraphNode
    
    init(_ neighbor: GraphNode) {
        self.neighbor = neighbor
    }
    
    static func == (_ lhs: Connection, rhs: Connection) -> Bool {
        return lhs.neighbor == rhs.neighbor
    }
}
