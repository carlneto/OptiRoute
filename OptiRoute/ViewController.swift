//
//  ViewController.swift
//  OptiRoute
//
//  Created by Carlos Neto on 04/04/2020.
//  Copyright © 2020 Carlos Neto. All rights reserved.
//
import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var generationLbl: UILabel!
    @IBOutlet weak var startBtn: UIButton!
    @IBOutlet weak var stopBtn: UIButton!
    @IBOutlet weak var undoBtn: UIButton!
    @IBOutlet weak var clearBtn: UIButton!
    @IBOutlet weak var sampleBtn: UIButton!
    
    let userLocations = "locations1"
    var generator: Generator?
    
    var locations = [String : CGPoint]() {
        didSet {
            var strs = [String]()
            for loc in locations {
                strs.append("\(loc.key),\(loc.value.x),\(loc.value.y)")
            }
            userLocations.keyForSaving(strs)
            drawPoints()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resetLocations(arr: userLocations.keyForRead())
        "locations".keyToRemoveObject(sync: false)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if mapView.point(inside: touch.location(in: mapView), with: event) {
            let location = touch.location(in: mapView)
            guard startBtn.isEnabled else { return }
            locations["\(locations.count)"] = location
        }
    }
    
    private func drawPoints() {
        self.mapView.layer.sublayers?.removeAll()
        self.locations.forEach { location in
            let p = location.value
            let idx = location.key
            let circle = UIBezierPath.init(arcCenter: p, radius: 5, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            let circleLayer = CAShapeLayer()
            circleLayer.path = circle.cgPath
            circleLayer.fillColor = UIColor.red.cgColor
            circleLayer.strokeColor = UIColor.red.cgColor
            let lbl = CATextLayer()
            let txt = "\(idx)"
            lbl.string = txt
            lbl.fontSize = 11
            lbl.alignmentMode = .center
            let aFont = lbl.font as? UIFont ?? UIFont.systemFont(ofSize: lbl.fontSize)
            let h = lbl.fontSize * 2
            let w = txt.widthFrom(height: h, usingFont: aFont)
            lbl.frame = CGRect(origin: p, size: CGSize(width: w, height: h)).offsetBy(dx: -w / 2, dy: 6)
            lbl.foregroundColor = UIColor.systemBlue.cgColor
            self.mapView.layer.addSublayer(lbl)
            self.mapView.layer.addSublayer(circleLayer)
        }
    }
    
    private func drawRoute(_ person: Person) {
        guard !person.body.isEmpty else { return }
        var organs = person.body
        guard let firstOrgan = organs.first, let firstLoc = firstOrgan.content as? CGPoint else { return }
        organs.remove(at: 0)
        drawPoints()
        DispatchQueue.main.async {
            let path = UIBezierPath()
            path.lineWidth = 1
            path.move(to: firstLoc)
            organs.forEach { organ in
                if let loc = organ.content as? CGPoint {
                    path.addLine(to: loc)
                }
            }
            path.addLine(to: firstLoc)
            let pathLayer = CAShapeLayer()
            pathLayer.path = path.cgPath
            pathLayer.fillColor = UIColor.clear.cgColor
            pathLayer.strokeColor = UIColor.brown.cgColor
            self.mapView.layer.addSublayer(pathLayer)
        }
    }
    
    private func resetLocations(arr: [String]) {
        var locs = [String : CGPoint]()
        arr.forEach {
            let pp = $0.split(separator: ",")
            let n = pp[0]
            let a = pp[1]
            let b = pp[2]
            guard !n.isEmpty, let x = Double(a), let y = Double(b) else { return }
            locs["\(n)"] = CGPoint(x: x, y: y)
        }
        locations = locs
    }
    
    @IBAction func startTap() {
        guard locations.count > 1 else { return }
        startBtn.isEnabled = false
        clearBtn.isEnabled = false
        undoBtn.isEnabled = false
        sampleBtn.isEnabled = false
        let body = Body.create(dict: locations)
        generator = Generator(subject: body)
        generator?.onNewGeneration = { (person, generation) in
            DispatchQueue.main.async {
                self.generationLbl.text = "Generation: \(generation)"
                self.drawRoute(person)
                self.startBtn.isEnabled = generation > 250
                self.clearBtn.isEnabled = generation > 250
                self.undoBtn.isEnabled = generation > 250
                self.sampleBtn.isEnabled = generation > 250
            }
        }
        generator?.startEvolution()
    }
    
    @IBAction func stopTap() {
        generator?.stopEvolution()
        startBtn.isEnabled = true
        clearBtn.isEnabled = true
        undoBtn.isEnabled = true
        sampleBtn.isEnabled = true
    }
    
    @IBAction func undoTap() {
        locations.removeValue(forKey: "\(locations.count - 1)")
    }
    
    @IBAction func clearTap() {
        locations.removeAll()
        mapView.layer.sublayers?.removeAll()
        generationLbl.text = "Generation: 0"
    }
    
    @IBAction func sampleTap() {
        //var locs = [String : CGPoint]()
        //for node in nodes {
        //    locs[node.name] = CGPoint(x: node.x * Body.wFactor, y: node.y * Body.hFactor - 30)
        //}
        //locations = locs
        let wFactor = Double(mapView.bounds.width - 10)
        let hFactor = Double(mapView.bounds.height - 10)
        while locations.count > 1, locations.count < 9 {
            let p = CGPoint(x: Double.random(in: 10 ... wFactor), y:  Double.random(in: 10 ... hFactor))
            locations["\(locations.count)"] = p
        }
        let p = CGPoint(x: Double.random(in: 10 ... wFactor), y:  Double.random(in: 10 ... hFactor))
        locations["\(locations.count)"] = p
    }
    
    let nodes = [
        (x:  40.0, y:  70.0, name: "A"),
        (x: 240.0, y: 630.0, name: "N"),
        (x: 200.0, y: 140.0, name: "D"),
        (x: 330.0, y:  80.0, name: "F"),
        (x: 320.0, y: 700.0, name: "O"),
        (x: 380.0, y: 140.0, name: "G"),
        (x: 130.0, y: 180.0, name: "C"),
        (x:  70.0, y: 130.0, name: "B"),
        (x: 400.0, y: 210.0, name: "H"),
        (x: 200.0, y: 490.0, name: "L"),
        (x: 240.0, y: 420.0, name: "K"),
        (x: 360.0, y: 280.0, name: "I"),
        (x: 300.0, y: 350.0, name: "J"),
        (x: 180.0, y: 570.0, name: "M"),
        (x: 240.0, y:  80.0, name: "E"),
        (x: 400.0, y: 750.0, name: "P")
    ]
}


extension Body {
    
    static let wFactor = Double(UIScreen.main.bounds.width / 450)
    static let hFactor = Double(UIScreen.main.bounds.height / 900)
    static let a = "0"
    static let b = "1"
    static let c = 0.0

    static func create(dict: [String : CGPoint]) -> Body {
        var body = Body()
        for point in dict {
            _ = body.inserted(name: "\(point.key)", content: point.value)
        }
        body.setWeights()
        return body
    }
    
    static func create(points: [CGPoint]) -> Body {
        var body = Body()
        for (idx, point) in points.enumerated() {
            _ = body.inserted(name: "\(idx)", content: point)
        }
        body.setWeights()
        return body
    }
    
    func setWeights() {
        for o1 in self {
            for o2 in self {
                guard o1 != o2 else { continue }
                if o1.name == Body.a, o2.name == Body.b {
                    o1.set(weight: Body.c, to: o2)
                    continue
                }
                if o1.name == Body.b, o2.name == Body.a {
                    o1.set(weight: Body.c, to: o2)
                    continue
                }
                let p1 = o1.content as! CGPoint
                let p2 = o2.content as! CGPoint
                let aWeight = hypot(Double(p1.x - p2.x), Double(p1.y - p2.y))
                o1.set(weight: aWeight, to: o2)
            }
        }
    }
}
