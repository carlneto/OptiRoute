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

    var geneticAlgorithm: GeneticAlgorithm?
    var locations: [CGPoint] = [] {
        didSet {
            var strs = [String]()
            for p in locations {
                strs.append("\(p.x),\(p.y)")
            }
            "locations".keyForSaving(strs)
            drawCities()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        resetLocations(arr: "locations".keyForRead())
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if mapView.point(inside: touch.location(in: mapView), with: event) {
            let location = touch.location(in: mapView)
            guard startBtn.isEnabled else { return }
            locations.append(location)
        }
    }
    
    private func drawCities() {
        self.mapView.layer.sublayers?.removeAll()
        self.locations.forEach { location in
            let circle = UIBezierPath.init(arcCenter: location, radius: 5, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            let circleLayer = CAShapeLayer()
            circleLayer.path = circle.cgPath
            circleLayer.fillColor = UIColor.red.cgColor
            circleLayer.strokeColor = UIColor.red.cgColor
            self.mapView.layer.addSublayer(circleLayer)
        }
    }
    
    private func drawRoute(route: Chromosome) {
        guard let firstCity = route.cities.first else { return }
        var otherCities = route.cities
        otherCities.remove(at: 0)
        drawCities()
        DispatchQueue.main.async {
            let path = UIBezierPath()
            path.lineWidth = 1
            path.move(to: firstCity.location)
            otherCities.forEach { city in
                path.addLine(to: city.location)
            }
            path.addLine(to: firstCity.location)
            let pathLayer = CAShapeLayer()
            pathLayer.path = path.cgPath
            pathLayer.fillColor = UIColor.clear.cgColor
            pathLayer.strokeColor = UIColor.black.cgColor
            self.mapView.layer.addSublayer(pathLayer)
        }
    }
    
    private func resetLocations(arr: [String]) {
        var locs: [CGPoint] = []
        arr.forEach {
            let pp = $0.split(separator: ",")
            guard let a = pp.first, let b = pp.last,
                let x = Double(a), let y = Double(b) else { return }
            locs.append(CGPoint(x: x, y: y))
        }
        locations = locs
        if locations.count > 0 {
            startTap()
        }
    }
    
    @IBAction func startTap() {
        guard locations.count > 1 else { return }
        startBtn.isEnabled = false
        clearBtn.isEnabled = false
        undoBtn.isEnabled = false
        sampleBtn.isEnabled = false
        geneticAlgorithm = GeneticAlgorithm(withCities: locations.map { City(location: $0) })
        geneticAlgorithm?.onNewGeneration = { (route, generation) in
            DispatchQueue.main.async {
                self.generationLbl.text = "Generation: \(generation)"//", distance: \(Int(route.distance))"
                self.drawRoute(route: route)
                self.startBtn.isEnabled = generation > 250
                self.clearBtn.isEnabled = generation > 250
                self.undoBtn.isEnabled = generation > 250
                self.sampleBtn.isEnabled = generation > 250
            }
        }
        geneticAlgorithm?.startEvolution()
    }

    @IBAction func stopTap() {
        geneticAlgorithm?.stopEvolution()
        startBtn.isEnabled = true
        clearBtn.isEnabled = true
        undoBtn.isEnabled = true
        sampleBtn.isEnabled = true
    }

    @IBAction func undoTap() {
        locations.removeLast()
    }

    @IBAction func clearTap() {
        locations.removeAll()
        mapView.layer.sublayers?.removeAll()
        generationLbl.text = "Generation: 0"
    }

    @IBAction func sampleTap() {
//        var locs: [CGPoint] = []
//        Node.nodes.forEach { locs.append(CGPoint(x: $0.location.x, y: $0.location.y))}
//        locations = locs
        let wFactor = Double(mapView.bounds.width - 10)
        let hFactor = Double(mapView.bounds.height - 10)
        let p = CGPoint(x: Double.random(in: 10 ... wFactor), y:  Double.random(in: 10 ... hFactor))
        locations.append(p)
    }
}

extension String {
    func keyForSaving(_ val: Any, sync: Bool = true) {
        func perform(_ key: String) {
            guard !key.isEmpty else { return }
            let userDefaults = UserDefaults.standard
            userDefaults.set(val, forKey: key)
            userDefaults.synchronize()
        }
        let key = self
        sync ? perform(key) : DispatchQueue.global(qos: .background).async { perform(key) }
    }
    func keyForRead() -> [String] {
        guard !isEmpty else { return [String]() }
        return UserDefaults.standard.stringArray(forKey: self) ?? [String]()
    }
}
