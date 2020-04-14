class Edge {
    
    let to: Node
    let weight: Double
    
    init(to node: Node, weight: Double) {
        assert(weight >= 0, "weight has to be equal or greater than zero")
        self.to = node
        self.weight = weight
    }
}

typealias Edges = [Edge]
