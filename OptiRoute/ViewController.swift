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
            generationLbl.text = "Locations: \(locations.count)"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resetLocations(arr: userLocations.keyForRead())
        "locations".keyToRemoveObject(sync: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.startTap()
        })
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
            let circle = UIBezierPath.init(arcCenter: p, radius: 3, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            let circleLayer = CAShapeLayer()
            circleLayer.path = circle.cgPath
            circleLayer.fillColor = UIColor.brown.cgColor
            circleLayer.strokeColor = UIColor.red.cgColor
            let lbl = CATextLayer()
            let txt = "\(idx)"
            lbl.string = txt
            lbl.fontSize = 10
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
    
    private func drawRoute(_ body: Body, isRound: Bool = true) {
        var organs = body
        guard !organs.isEmpty else { return }
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
            if isRound {
                path.addLine(to: firstLoc)
            }
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
        var dict = [String : Any]()
        for point in locations { dict["\(point.key)"] = point.value }
        generator = Generator(organsNameContent: dict, muscles: { body, isLinear -> Body in
            for o1 in body {
                for o2 in body {
                    guard o1 != o2 else { continue }
                    let p1 = o1.content as! CGPoint
                    let p2 = o2.content as! CGPoint
                    let aWeight = hypot(Double(p1.x - p2.x), Double(p1.y - p2.y))
                    o1.set(weight: aWeight, to: o2)
                }
            }
            if isLinear, let a = body.organ(by: "0"), let b = body.organ(by: "1") {
                a.set(weight: 0.0, to: b)
                b.set(weight: 0.0, to: a)
            }
            return body
        }, isCircle: false)
        generator?.onNewGeneration = { body, weight in
            DispatchQueue.main.async {
                self.generationLbl.text = "\(weight)"
                self.drawRoute(body)
            }
        }
        generator?.onEvolutionEnd = { vipBody, weight, isCircle in
            DispatchQueue.main.async {
                self.generationLbl.text = "Fitness: \(weight)"
                self.drawRoute(vipBody, isRound: isCircle)
                self.startBtn.isEnabled = true
                self.clearBtn.isEnabled = true
                self.undoBtn.isEnabled = true
                self.sampleBtn.isEnabled = true
            }
        }
        generator?.startEvolution()
        drawPoints()
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
        let txt = "Clear", ok = "Ok?"
        if let text = clearBtn.titleLabel?.text, text == ok {
            clearBtn.setTitle(txt, for: .normal)
            locations.removeAll()
            mapView.layer.sublayers?.removeAll()
            generationLbl.text = "Locations: \(locations.count)"
        } else {
            clearBtn.setTitle(ok, for: .normal)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                self.clearBtn.setTitle(txt, for: .normal)
            })
        }
    }
    
    @IBAction func sampleTap() {
        if locations.isEmpty {
            let w = Double(mapView.bounds.width / 450)
            let h = Double(mapView.bounds.height / 800)
            var locs = [String : CGPoint]()
            for node in nodes1 {
                locs[node.name] = CGPoint(x: node.x * w, y: node.y * h - 5)
            }
            locations = locs
            return
        }
        if locations.count == 1 {
            let w = Double(mapView.bounds.width / 420)
            let h = Double(mapView.bounds.height / 800)
            var locs = [String : CGPoint]()
            for node in nodes2 {
                locs[node.name] = CGPoint(x: node.x * w + 10, y: node.y * h + 10)
            }
            locations = locs
            return
        }
        let wFactor = Double(mapView.bounds.width - 10)
        let hFactor = Double(mapView.bounds.height - 10)
        for _ in 0 ... 9 {
            var p = CGPoint(x: Double.random(in: 10 ... wFactor), y:  Double.random(in: 10 ... hFactor))
            while locationsContains(point: p)  {
                p = CGPoint(x: Double.random(in: 10 ... wFactor), y:  Double.random(in: 10 ... hFactor))
            }
            locations["\(locations.count)"] = p
        }
    }
    
    func locationsContains(point: CGPoint) -> Bool {
        for loc in locations {
            let p0 = loc.value
            let hyp = hypot(Double(p0.x - point.x), Double(p0.y - point.y))
            if hyp < 20 {
                return true
            }
        }
        return false
    }
    
    let nodes1 = [
        (x:  50.0, y:  50.0, name:  "1"),
        (x: 230.0, y: 650.0, name: "12"),
        (x: 200.0, y: 140.0, name:  "5"),
        (x: 335.0, y:  85.0, name:  "9"),
        (x: 310.0, y: 710.0, name: "11"),
        (x: 390.0, y: 130.0, name: "14"),
        (x: 130.0, y: 170.0, name:  "3"),
        (x:  70.0, y: 125.0, name:  "2"),
        (x: 390.0, y: 210.0, name:  "7"),
        (x: 190.0, y: 490.0, name: "10"),
        (x: 240.0, y: 420.0, name: "15"),
        (x: 360.0, y: 280.0, name:  "4"),
        (x: 300.0, y: 350.0, name: "13"),
        (x: 170.0, y: 580.0, name:  "8"),
        (x: 260.0, y:  90.0, name:  "6"),
        (x: 400.0, y: 760.0, name:  "0")
    ]
    
    let nodes2 = [
        (x:  34, y: 259, name:  "7"),
        (x: 230, y: 374, name: "17"),
        (x: 159, y: 109, name:  "9"),
        (x: 288, y: 750, name: "22"),
        (x: 253, y: 449, name: "18"),
        (x: 380, y: 669, name: "21"),
        (x: 379, y: 773, name:  "0"),
        (x: 290, y: 212, name: "15"),
        (x: 391, y:  71, name: "13"),
        (x: 334, y: 595, name: "20"),
        (x: 340, y: 135, name: "14"),
        (x: 401, y: 741, name:  "1"),
        (x: 289, y: 530, name: "19"),
        (x: 229, y:  44, name: "10"),
        (x:  87, y: 184, name:  "8"),
        (x: 398, y: 3.5, name: "12"),
        (x: 213, y: 706, name:  "2"),
        (x: 310, y: 3.5, name: "11"),
        (x: 255, y: 290, name: "16"),
        (x: 147, y: 631, name:  "3"),
        (x:  88, y: 549, name:  "4"),
        (x:  35, y: 450, name:  "5"),
        (x:20.5, y: 349, name:  "6")
    ]
}
