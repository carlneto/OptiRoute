import UIKit

class Person: Hashable {
    
    let body: Body
    
    private var _weight: Double?
    var weight: Double {
        if _weight == nil { _weight = calculateWeight() }
        return _weight ?? 0.0
    }
    
    init(body: Body) {
        self.body = body
    }
    
    private func calculateWeight() -> Double {
        var result: Double = 0.0
        var previousOrgan: Organ?
        body.forEach { organ in
            if let previous = previousOrgan { result += previous.edgeTo(other: organ) }
            previousOrgan = organ
        }
        guard let first = body.first, let last = body.last else { return result }
        return result + first.edgeTo(other: last)
    }

    var description: String {
        var ret = "["
        for organ in body { ret += organ.name + ", " }
        return ret + "]"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(body)
    }
    
    static func == (lhs: Person, rhs: Person) -> Bool {
        return lhs.body == rhs.body
    }
    
    // Probability of being selected from 0 to 1
    func fitnessProb(withTotalWeight totalWeigh: Double) -> Double {
        return 1 - (weight / totalWeigh)
    }
    
    /// Person operators

    func produceOffspring(secondParent: Person) -> Person {
        let firstParent = self
        let slice = Int(arc4random_uniform(UInt32(firstParent.body.count)))
        var body = Body(firstParent.body[0..<slice])
        var idx = slice
        while body.count < secondParent.body.count {
            let organ = secondParent.body[idx]
            if !body.contains(organ) {
                body.append(organ)
            }
            idx = (idx + 1) % secondParent.body.count
        }
        return Person(body: body)
    }

    private func mutate(probability: Double) -> Person {
        let child = self
        if probability >= Double(Double(arc4random()) / Double(UINT32_MAX)) {
            let firstIdx = Int(arc4random_uniform(UInt32(child.body.count)))
            let secondIdx = Int(arc4random_uniform(UInt32(child.body.count)))
            var body = child.body
            body.swapAt(firstIdx, secondIdx)
            return Person(body: body)
        }
        return child
    }

    func mutate(withOther parentTwo: Person, probability percentage: Double) -> Person {
        let child = produceOffspring(secondParent: parentTwo)
        let finalChild = child.mutate(probability: percentage)
        return finalChild
    }
}
