class Graph: CustomStringConvertible, Equatable {
    
    private(set) var nodes: [GraphNode]
    
    init() {
        self.nodes = []
    }
    
    @discardableResult func addNode(x: Double, y: Double, name: String) -> GraphNode {
        let node = GraphNode(x: x, y: y, name: name)
        nodes.append(node)
        return node
    }
    
    func addConnection(_ source: GraphNode, neighbor: GraphNode) {
        let connection = Connection(neighbor)
        source.neighbors.append(connection)
    }
    
    var description: String {
        var description = ""
        
        for node in nodes {
            if !node.neighbors.isEmpty {
                description += "[node: \(node.name) connections: \(node.neighbors.map { $0.neighbor.name})]"
            }
        }
        return description
    }
    
    func findNodeWithLabel(_ label: String) -> GraphNode {
        return nodes.filter { $0.name == label }.first!
    }
    
    func duplicate() -> Graph {
        let duplicated = Graph()
        
        for node in nodes {
            duplicated.addNode(x: node.x, y: node.y, name: node.name)
        }
        
        for node in nodes {
            for connection in node.neighbors {
                let source = duplicated.findNodeWithLabel(node.name)
                let neighbour = duplicated.findNodeWithLabel(connection.neighbor.name)
                duplicated.addConnection(source, neighbor: neighbour)
            }
        }
        
        return duplicated
    }
    
    static func == (_ lhs: Graph, rhs: Graph) -> Bool {
        return lhs.nodes == rhs.nodes
    }
}
