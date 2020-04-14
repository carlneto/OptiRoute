class Node {
    
    var visited = false
    var edges: Edges = []
    var name: String
    let content: Any
    
    init(name: String, content: Any) {
        self.name = name
        self.content = content
    }
}

typealias Nodes = [Node]
