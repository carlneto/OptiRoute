import UIKit

class Dijkstra {

    static func runSPF(samples: [(x: Double, y: Double, name: String)]) {

        var sourceNode: Node!
        var destinNode: Node!

        var nodes = Nodes()
        for sample in samples {
            let point = CGPoint(x: sample.x, y: sample.y)
            let node = Node(name: sample.name, content: point)
            if node.name == "0" {
                sourceNode = node
            }
            if node.name == "1" {
                destinNode = node
            }
            nodes.append(node)
        }
        for node0 in nodes {
            for node1 in nodes {
                guard node0.name != node1.name else { continue }
                if node0.name == "0", node1.name == "1" { continue }
                if node0.name == "1", node1.name == "0" { continue }
                guard let p0 = node0.content as? CGPoint, let p1 = node1.content as? CGPoint else { continue }
                let connection = Edge(to: node1, weight: hypot(Double(p0.x - p1.x), Double(p0.y - p1.y)))
                node0.edges.append(connection)
            }
        }
        
        guard let track = shortestPath(source: sourceNode, destination: destinNode) else { return }
        
        for node in track.nodes.reversed() {
            print(node.name, separator: " ")
        }
        
        let succession: [String] = track.nodes.reversed().map { $0.name + " " }
        
        if succession.count > 0 {
            print("🏁 Quickest path: \(succession)")
        } else {
            print("💥 No path between \(sourceNode.name) & \(destinNode.name)")
        }
    }
    
    static func shortestPath(source: Node, destination: Node) -> Track? {
        var tracks: Tracks = []
        let trackToSource = Track(to: source)
        tracks.append(trackToSource)
        while !tracks.isEmpty {
            let cheapestTrack = tracks.removeFirst()
            guard !cheapestTrack.node.visited else { continue }
            cheapestTrack.node.visited = true
            if cheapestTrack.node.name == destination.name {
                return cheapestTrack
            }
            for edge in cheapestTrack.node.edges where !edge.to.visited {
                let track = Track(to: edge.to, via: edge, previousTrack: cheapestTrack)
                tracks.append(track)
                tracks.sort { $0.cumulativeWeight < $1.cumulativeWeight }
            }
        }
        return nil
    }
}
