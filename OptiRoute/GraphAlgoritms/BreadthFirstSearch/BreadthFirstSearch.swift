import UIKit

class BreadthFirstSearch {
    
    static func breadthFirstSearch(_ graph: Graph, source: GraphNode) -> [String] {
        var queue = Queue<GraphNode>()
        queue.enqueue(source)
        
        var nodesExplored = [source.name]
        source.visited = true
        
        while let node = queue.dequeue() {
            for connection in node.neighbors {
                let neighborNode = connection.neighbor
                if !neighborNode.visited {
                    queue.enqueue(neighborNode)
                    neighborNode.visited = true
                    nodesExplored.append(neighborNode.name)
                }
            }
        }
        
        return nodesExplored
    }
    
    static func runBreadthFirstSearch(samples: [(x: Double, y: Double, name: String)]) {
        
        let graph = Graph()
        
        for sample in samples {
            graph.addNode(x: sample.x, y: sample.y, name: sample.name)
        }
        
        var source: GraphNode!
        let nodes = graph.nodes
        for node0 in nodes {
            if node0.name == "0" {
                source = node0
            }
            var nodesWeights = [(weight: Double, node0: GraphNode, node1: GraphNode)]()
            for node1 in nodes {
                func notContainsNodes(_ n0: GraphNode, _ n1: GraphNode) -> Bool {
                    for nodesWeight in nodesWeights {
                        if n0 == nodesWeight.node0, n1 == nodesWeight.node1 {
                            return false
                        }
                    }
                    return true
                }
                guard node0.name != node1.name else { continue }
                if node0.name == "0", node1.name == "1" { continue }
                if node0.name == "1", node1.name == "0" { continue }
                guard notContainsNodes(node0, node1), notContainsNodes(node1, node0) else { continue }
                let weight = node0.weight(other: node1)
                nodesWeights.append((weight: weight, node0: node0, node1: node1))
            }
            nodesWeights.sort { $0.weight < $1.weight }
            for (idx, item) in nodesWeights.enumerated() {
                print(idx)
//                guard idx < 3 else { break }
                graph.addConnection(item.node0, neighbor: item.node1)
            }
        }
        
        let nodesExplored = breadthFirstSearch(graph, source: source)
        print(nodesExplored)
        let joined = nodesExplored.joined()
        print(joined)
    }
}
