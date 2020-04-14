class Track {
    
    let cumulativeWeight: Double
    let node: Node
    let previousTrack: Track?
    
    init(to node: Node, via edge: Edge? = nil, previousTrack path: Track? = nil) {
        if let previousTrack = path, let viaEdge = edge {
            self.cumulativeWeight = viaEdge.weight + previousTrack.cumulativeWeight
        } else {
            self.cumulativeWeight = 0
        }
        
        self.node = node
        self.previousTrack = path
    }
    
    var nodes: Nodes {
        var array: Nodes = [self.node]
        var iterativePath = self
        while let path = iterativePath.previousTrack {
            array.append(path.node)
            iterativePath = path
        }
        return array
    }
}

typealias Tracks = [Track]
