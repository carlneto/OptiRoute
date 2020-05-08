import MapKit

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var generationLbl: UILabel!
    @IBOutlet weak var startBtn: UIButton!
    @IBOutlet weak var stopBtn: UIButton!
    @IBOutlet weak var undoBtn: UIButton!
    @IBOutlet weak var clearBtn: UIButton!
    @IBOutlet weak var sampleBtn: UIButton!
    
    private var routes = [[String] : MKRoute]()
    private var weights = [[String] : Double]()
    let userLocations = "locations2"
    var generator: Generator?
    
    var locations = [String : CLLocationCoordinate2D]() {
        didSet {
            generationLbl.text = "Locations: \(locations.count)"
        }
    }
    
    func add(location: CLLocationCoordinate2D) {
        self.locations["\(self.locations.count)"] = location
        //setRoutes()
    }
    
    func setRoutes() {
        var locs = [CLLocationCoordinate2D]()
        for loc in locations {
            guard locs.count < 25 else {
                break
            }
            let coordinate = loc.value
            locs.append(coordinate)
        }
        guard locs.count > 2 else { return }
        MapBoxMatrix.get(locations: locs) { locals, model  in
            guard let m = model, let durations = m.durations else { return }
            for (i, source) in locals.enumerated() {
                for (j, destination) in locals.enumerated() {
                    guard i != j else { continue }
                    let weight = durations[i][j]
                    self.weights[[source.str, destination.str]] = weight
                }
            }
            print(self.weights)
        }
    }
    
    func setRoutes_2() {
        var locs = [[Double]]()
        for loc in locations {
            let coordinate = loc.value
            locs.append([coordinate.longitude, coordinate.latitude])
        }
        guard locs.count > 2 else { return }
        ORMatrix.get(locations: locs) { model in
            guard let m = model, let durations = m.durations else { return }
            for (i, source) in locs.enumerated() {
                for (j, destination) in locs.enumerated() {
                    guard source != destination else { continue }
                    let weight = durations[i][j]
                    let left = "\(source[mod: 1].zeros(6)),\(source[mod: 0].zeros(6))"
                    let right = "\(destination[mod: 1].zeros(6)),\(destination[mod: 0].zeros(6))"
                    self.weights[[left, right]] = weight
                }
            }
            print(self.weights)
        }
    }
    
    func setRoutes_1() {
        if self.locations.count > 0 {
            var reqs = [(source: CLLocationCoordinate2D, destination: CLLocationCoordinate2D)]()
            func set(source: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) {
                guard self.routes[[source.str, destination.str]] == nil else { return }
                self.startBtn.isEnabled = false
                let sourcePlacemark = MKPlacemark(coordinate: source, addressDictionary: nil)
                let destinationPlacemark = MKPlacemark(coordinate: destination, addressDictionary: nil)
                let request = MKDirections.Request()
                request.source = MKMapItem(placemark: sourcePlacemark)
                request.destination = MKMapItem(placemark: destinationPlacemark)
                request.transportType = .automobile
                let directions = MKDirections(request: request)
                directions.calculate { response, error in
                    guard error == nil else {
                        if let error = error as? MKError, let duration = error.throttleStateResetTimeRemaining {
                            print(error)
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 1, execute: {
                                self.setRoutes()
                            })
                        } else {
                            print(error.debugDescription)
                        }
                        return
                    }
                    if let route = response?.routes.first {
                        self.routes[[source.str, destination.str]] = route
                        if reqs.count > 0 {
                            let req = reqs.removeFirst()
                            print("requestCount.decreased \(reqs.count) - Route: \(route.name)")
                            set(source: req.source, destination: req.destination)
                        } else {
                            self.startBtn.isEnabled = true
                        }
                    }
                }
            }
            for loc1 in locations {
                for loc2 in locations {
                    guard loc1.key != loc2.key else { continue }
                    guard self.routes[[loc1.value.str, loc2.value.str]] == nil else { continue }
                    reqs.append((source: loc1.value, destination: loc2.value))
                }
            }
            if reqs.count > 0 {
                let req = reqs.removeFirst()
                set(source: req.source, destination: req.destination)
            }
        }
    }
    
    func setPolyline(source: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) -> Void {
        let sourcePlacemark = MKPlacemark(coordinate: source, addressDictionary: nil)
        let destinationPlacemark = MKPlacemark(coordinate: destination, addressDictionary: nil)
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)
        request.transportType = .automobile
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard error == nil else {
                if let error = error as? MKError, let duration = error.throttleStateResetTimeRemaining {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration + 1, execute: {
                        self.setPolyline(source: source, destination: destination)
                    })
                } else {
                    print(error.debugDescription)
                }
                return
            }
            if let route = response?.routes.first {
                self.mapView.addOverlay(route.polyline)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let ptCenter = CLLocation(latitude: 39.464345, longitude: -8.1950642)
        self.mapView.centerToLocation(ptCenter, regionRadius: 1_200_000)
        let region = MKCoordinateRegion(center: ptCenter.coordinate, latitudinalMeters: 250_000, longitudinalMeters: 100_000)
        self.mapView.setCameraBoundary(MKMapView.CameraBoundary(coordinateRegion: region), animated: true)
        let zoomRange = MKMapView.CameraZoomRange(maxCenterCoordinateDistance: 150_000)
        self.mapView.setCameraZoomRange(zoomRange, animated: true)
        self.mapView.delegate = self

        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(tap(sender:)))
        gesture.delegate = self
        self.mapView.addGestureRecognizer(gesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let locs = CLLocationCoordinate2D.locs()
        for i in 0..<locs.count {
            guard let loc = locs["\(i)"] else { fatalError() }
            addAnnotation(location: loc)
        }
    }
    
    @objc func tap(sender: UILongPressGestureRecognizer) {
        guard sender.state == .ended, self.startBtn.isEnabled  else { return }
        let locationInView = sender.location(in: self.mapView)
        let locationOnMap = self.mapView.convert(locationInView, toCoordinateFrom: self.mapView)
        self.addAnnotation(location: locationOnMap)
    }
    
    func addAnnotation(location: CLLocationCoordinate2D) {
        let annotation = MyPointAnnotation()
        annotation.coordinate = location
        let txt = "\(self.locations.count)"
        annotation.title = txt
        annotation.subtitle = txt
        annotation.isEndingPoint = txt == "0"
        annotation.isStartingPoint = txt == "1"
        self.mapView.addAnnotation(annotation)
        self.mapView.selectAnnotation(annotation, animated: false)
        self.add(location: location)
    }
    
    private func resetLocations(arr: [String]) {
        "locations".keyToRemoveObject(sync: false)
        "locations1".keyToRemoveObject(sync: false)
        var locs = [String : CLLocationCoordinate2D]()
        arr.forEach {
            let pp = $0.split(separator: ",")
            let n = pp[0]
            let a = pp[1]
            let b = pp[2]
            guard !n.isEmpty, let latitude = Double(a), let longitude = Double(b) else { return }
            locs["\(n)"] = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        self.locations = locs
    }
    
    @IBAction func startTap() {
        self.generationLbl.text = "Locations: \(self.locations.count)"
        guard self.locations.count > 2 else { return }
        self.startBtn.isEnabled = false
        self.clearBtn.isEnabled = false
        self.undoBtn.isEnabled = false
        self.sampleBtn.isEnabled = false
        var dict = [String : Any]()
        for point in self.locations { dict["\(point.key)"] = point.value }
        self.generator = Generator(organsNameContent: dict, muscles: { body, isLinear -> Body in
            for o1 in body {
                for o2 in body {
                    guard o1 != o2 else { continue }
                    let p1 = o1.content as! CLLocationCoordinate2D
                    let p2 = o2.content as! CLLocationCoordinate2D
                    guard let weight = self.weights[[p1.str, p2.str]] else {
                        print("self.weights[[\(p1.str), \(p2.str)]]")
                        continue
                    }
                    o1.set(weight: weight, to: o2)
                }
            }
            if isLinear, let a = body.organ(by: "0"), let b = body.organ(by: "1") {
                a.set(weight: 0.0, to: b)
                b.set(weight: 0.0, to: a)
            }
            return body
        }, isCircle: false)
        self.generator?.onNewGeneration = { body, weight in
            DispatchQueue.main.async {
                self.generationLbl.text = "\(weight)"
            }
        }
        self.generator?.onEvolutionEnd = { vipBody, weight, isCircle in
            DispatchQueue.main.async {
                self.generationLbl.text = "Fitness: \(weight)"
                self.mapView.removeAnnotations(self.mapView.annotations)
                self.mapView.removeOverlays(self.mapView.overlays)
                let lenght = vipBody.count
                var locs = [CLLocationCoordinate2D]()
                if lenght > 2, self.locations.count == lenght {
                    self.mapView.removeAnnotations(self.mapView.annotations)
                    for (idx, organ) in vipBody.enumerated() {
                        guard let loc = organ.content as? CLLocationCoordinate2D else { break }
                        locs.append(loc)
                        let point = MyPointAnnotation()
                        point.coordinate = loc
                        point.title = "\(organ.name)"
                        
                        if idx == 0 {
                            point.subtitle = "S"
                            point.isStartingPoint = true
                        } else if idx == vipBody.count - 1 {
                            point.subtitle = "E"
                            point.isEndingPoint = true
                        }
                        self.mapView.addAnnotation(point)
                        self.mapView.selectAnnotation(point, animated: true)
                        let loc0 = vipBody[mod: idx - 1].content as! CLLocationCoordinate2D
                        if idx > 0 {
                            self.setPolyline(source: loc0, destination: loc)
                            //self.mapView.addOverlay(self.routes[[loc0.str, loc.str]]!.polyline)
                        }
                    }
                }
                print(vipBody.str)
                print(Person(body: vipBody).str)
                //self.drawRoute(vipBody, isRound: isCircle)
                self.startBtn.isEnabled = true
                self.clearBtn.isEnabled = true
                self.undoBtn.isEnabled = true
                self.sampleBtn.isEnabled = true
            }
        }
        self.generator?.startEvolution()
    }
    
    @IBAction func stopTap() {
        self.generator?.stopEvolution()
        self.startBtn.isEnabled = true
        self.clearBtn.isEnabled = true
        self.undoBtn.isEnabled = true
        self.sampleBtn.isEnabled = true
    }
    
    @IBAction func undoTap() {
        self.locations.removeValue(forKey: "\(locations.count - 1)")
        setRoutes()
    }
    
    @IBAction func clearTap() {
        let txt = "Clear", ok = "Ok?"
        if let text = clearBtn.titleLabel?.text, text == ok {
            self.clearBtn.setTitle(txt, for: .normal)
            self.locations.removeAll()
            self.generationLbl.text = "Locations: \(locations.count)"
        } else {
            self.clearBtn.setTitle(ok, for: .normal)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                self.clearBtn.setTitle(txt, for: .normal)
            })
        }
    }
    
    @IBAction func sampleTap() {
        print("sampleTap()")
        setRoutes()
    }
}

/// Helpers

private extension MKMapView {
    func centerToLocation(_ location: CLLocation, regionRadius: CLLocationDistance = 1000) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                  latitudinalMeters: regionRadius,
                                                  longitudinalMeters: regionRadius)
        setRegion(coordinateRegion, animated: true)
    }
    
    func calculateDistancefrom(departureDate: Date, arrivalDate: Date,
                               sourceLocation: MKMapItem, destinationLocation: MKMapItem,
                               doneSearching: @escaping (_ distance: CLLocationDistance) -> Void) {
        
        let request: MKDirections.Request = MKDirections.Request()
        
        request.departureDate = departureDate
        request.arrivalDate = arrivalDate
        
        request.source = sourceLocation
        request.destination = destinationLocation
        
        request.requestsAlternateRoutes = true
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { (directions, error) in
            if var routeResponse = directions?.routes {
                routeResponse.sort(by: {$0.expectedTravelTime <
                    $1.expectedTravelTime})
                let quickestRouteForSegment: MKRoute = routeResponse[0]
                
                doneSearching(quickestRouteForSegment.distance)
            }
        }
    }
    
    func getDistance(departureDate: Date, arrivalDate: Date,
                     startLocation: CLLocation, endLocation: CLLocation,
                     completionHandler: @escaping (_ distance: CLLocationDistance) -> Void) {
        
        let destinationItem = MKMapItem(placemark: MKPlacemark(coordinate: startLocation.coordinate))
        let sourceItem = MKMapItem(placemark: MKPlacemark(coordinate: endLocation.coordinate))
        self.calculateDistancefrom(departureDate: departureDate, arrivalDate: arrivalDate,
                                   sourceLocation: sourceItem, destinationLocation: destinationItem,
                                   doneSearching: { distance in
                                    completionHandler(distance)
        })
    }
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue.withAlphaComponent(0.5)
        renderer.lineWidth = 5
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let point = annotation as? MyPointAnnotation {
            let identifier = "pointAnnotationView"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
            
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView!.canShowCallout = true
            } else {
                annotationView!.annotation = point
            }
            if point.isStartingPoint {
                annotationView!.pinTintColor = .red
            } else if point.isEndingPoint {
                annotationView!.pinTintColor = .green
            } else {
                annotationView!.pinTintColor = .blue
            }
            return annotationView
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let pinView = view as? MKPinAnnotationView {
            print("tapped on pin: \(String(describing: pinView.annotation?.title))")
        } else {
            print("tapped on pin \(view.debugDescription)")
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            if let annotationTitle = view.annotation?.title, let txt = annotationTitle {
                print("annotationTitle: \(txt)")
            }
        }
    }
}

class MyPointAnnotation : MKPointAnnotation {
    var isStartingPoint = false
    var isEndingPoint = false
}

extension MKError {
    var throttleStateResetTimeRemaining: TimeInterval? {
        guard code == MKError.loadingThrottled,
            let errorDict = errorUserInfo["MKErrorGEOErrorUserInfo"] as? [String: Any],
            let duration = (errorDict["timeUntilReset"] as? NSNumber)?.doubleValue else {
                return nil
        }
        return duration
    }
}

extension CLLocationCoordinate2D {
    func distance(to: CLLocationCoordinate2D) -> CLLocationDistance {
        let origin = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let destination = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return destination.distance(from: origin)
    }
    var str: String {
        return "\(self.latitude.zeros(6)),\(self.longitude.zeros(6))"
    }
    static func locs() -> [String : CLLocationCoordinate2D] {
        return [
            "86" : CLLocationCoordinate2D(latitude: 39.777882835792866, longitude: -7.8566471541438432),
            "48" : CLLocationCoordinate2D(latitude: 39.024882147408107, longitude: -8.793454590441911),
            "91" : CLLocationCoordinate2D(latitude: 39.203098855020727, longitude: -8.5537726428995029),
            "33" : CLLocationCoordinate2D(latitude: 39.066211959624553, longitude: -8.7565634399931014),
            "45" : CLLocationCoordinate2D(latitude: 39.329234263465509, longitude: -8.5771437076681138),
            "82" : CLLocationCoordinate2D(latitude: 40.015656367999327, longitude: -8.5345569208605809),
            "68" : CLLocationCoordinate2D(latitude: 39.237783380217365, longitude: -8.8336476651001874),
            "0"  : CLLocationCoordinate2D(latitude: 39.462738688373264, longitude: -8.4680418814375571),
            "97" : CLLocationCoordinate2D(latitude: 39.083280612875313, longitude: -8.405829796703614),
            "101": CLLocationCoordinate2D(latitude: 39.479639950291215, longitude: -9.0450329036834205),
            "11" : CLLocationCoordinate2D(latitude: 39.47633196634311,  longitude: -8.3377126932773535),
            "16" : CLLocationCoordinate2D(latitude: 39.554609239153564, longitude: -8.2852900965348795),
            "21" : CLLocationCoordinate2D(latitude: 39.537760098622442, longitude: -8.3835175071969275),
            "95" : CLLocationCoordinate2D(latitude: 39.320022762994427, longitude: -7.809421143085558),
            "85" : CLLocationCoordinate2D(latitude: 39.750003251434407, longitude: -8.5885082901583303),
            "50" : CLLocationCoordinate2D(latitude: 39.362177215096438, longitude: -8.6218313707234415),
            "4"  : CLLocationCoordinate2D(latitude: 39.648459543915209, longitude: -7.4985460138634039),
            "96" : CLLocationCoordinate2D(latitude: 39.309232137479,    longitude: -7.9101819350248093),
            "39" : CLLocationCoordinate2D(latitude: 39.761707575679679, longitude: -8.2357929614369425),
            "40" : CLLocationCoordinate2D(latitude: 39.724054025655306, longitude: -8.3383545560130017),
            "25" : CLLocationCoordinate2D(latitude: 39.538376216715164, longitude: -8.7561092410756771),
            "57" : CLLocationCoordinate2D(latitude: 39.714838150204002, longitude: -7.8636299142674773),
            "65" : CLLocationCoordinate2D(latitude: 39.277947649684791, longitude: -8.5420277904468946),
            "8"  : CLLocationCoordinate2D(latitude: 39.551243490039155, longitude: -7.9947425533631247),
            "60" : CLLocationCoordinate2D(latitude: 39.786039531945192, longitude: -7.67245762522316),
            "81" : CLLocationCoordinate2D(latitude: 40.045045111867267, longitude: -8.4538990582552458),
            "83" : CLLocationCoordinate2D(latitude: 39.951592445093411, longitude: -8.6289882618710863),
            "84" : CLLocationCoordinate2D(latitude: 39.938440137788604, longitude: -8.8624445302815786),
            "70" : CLLocationCoordinate2D(latitude: 39.351374003432426, longitude: -8.1395036189324799),
            "7"  : CLLocationCoordinate2D(latitude: 39.463372577537996, longitude: -7.9356045571241225),
            "12" : CLLocationCoordinate2D(latitude: 39.60220996532891,  longitude: -8.4145423922871032),
            "49" : CLLocationCoordinate2D(latitude: 39.38411374736603,  longitude: -8.6614810027792544),
            "28" : CLLocationCoordinate2D(latitude: 39.848522579828028, longitude: -8.8395841850087891),
            "47" : CLLocationCoordinate2D(latitude: 39.037132636756155, longitude: -8.9334696916733094),
            "43" : CLLocationCoordinate2D(latitude: 39.494712358560577, longitude: -7.8346829915431613),
            "22" : CLLocationCoordinate2D(latitude: 39.588256640527021, longitude: -8.513577314288483),
            "10" : CLLocationCoordinate2D(latitude: 39.418899719057208, longitude: -8.4153029633362451),
            "76" : CLLocationCoordinate2D(latitude: 39.87101325454924,  longitude: -8.4430239123529987),
            "77" : CLLocationCoordinate2D(latitude: 39.786559543166732, longitude: -8.4652899393921359),
            "34" : CLLocationCoordinate2D(latitude: 39.213740160738382, longitude: -8.3998162765981021),
            "20" : CLLocationCoordinate2D(latitude: 39.457854503080199, longitude: -8.2461705782192496),
            "9"  : CLLocationCoordinate2D(latitude: 39.462825429646301, longitude: -8.1977045025110158),
            "87" : CLLocationCoordinate2D(latitude: 39.701594178737423, longitude: -8.0699424143145961),
            "94" : CLLocationCoordinate2D(latitude: 39.291459722433103, longitude: -7.429587823647438),
            "15" : CLLocationCoordinate2D(latitude: 39.607187166029348, longitude: -8.2558845266018466),
            "26" : CLLocationCoordinate2D(latitude: 39.656292884088913, longitude: -8.5794083708609037),
            "31" : CLLocationCoordinate2D(latitude: 39.108523056809133, longitude: -8.7389603233944513),
            "17" : CLLocationCoordinate2D(latitude: 39.495563647096105, longitude: -7.9565782730445278),
            "66" : CLLocationCoordinate2D(latitude: 39.326201449020402, longitude: -8.2953926302849652),
            "53" : CLLocationCoordinate2D(latitude: 39.515204468326743, longitude: -8.6177715722806454),
            "99" : CLLocationCoordinate2D(latitude: 39.033273621527258, longitude: -8.6347069600679447),
            "41" : CLLocationCoordinate2D(latitude: 39.635004018709026, longitude: -7.9631114171778563),
            "88" : CLLocationCoordinate2D(latitude: 39.642997304607007, longitude: -8.190615669468059),
            "35" : CLLocationCoordinate2D(latitude: 39.363811016100755, longitude: -8.223780054698409),
            "54" : CLLocationCoordinate2D(latitude: 39.660028133539157, longitude: -8.722014093862839),
            "78" : CLLocationCoordinate2D(latitude: 39.824158470130669, longitude: -8.5778108263661466),
            "62" : CLLocationCoordinate2D(latitude: 39.092075197462776, longitude: -8.0346693832889855),
            "30" : CLLocationCoordinate2D(latitude: 39.874107269237186, longitude: -8.9719765109854563),
            "72" : CLLocationCoordinate2D(latitude: 39.73039007179139,  longitude: -8.231256667849749),
            "32" : CLLocationCoordinate2D(latitude: 39.140178254652,    longitude: -8.6862215680938846),
            "6"  : CLLocationCoordinate2D(latitude: 39.245804819189686, longitude: -8.0090895112292344),
            "51" : CLLocationCoordinate2D(latitude: 39.572069107213252, longitude: -8.6011754117812416),
            "79" : CLLocationCoordinate2D(latitude: 40.178458555512037, longitude: -8.6967181694940052),
            "44" : CLLocationCoordinate2D(latitude: 39.529614427942931, longitude: -7.8549726611651352),
            "55" : CLLocationCoordinate2D(latitude: 39.740636678372084, longitude: -8.8103011588827655),
            "59" : CLLocationCoordinate2D(latitude: 39.751303529829215, longitude: -7.6210654776484148),
            "67" : CLLocationCoordinate2D(latitude: 39.415704669461832, longitude: -8.3118209600939679),
            "46" : CLLocationCoordinate2D(latitude: 39.303110513345416, longitude: -8.573018643069986),
            "38" : CLLocationCoordinate2D(latitude: 39.804568537548363, longitude: -8.0986016039615265),
            "92" : CLLocationCoordinate2D(latitude: 39.056998179557922, longitude: -7.8913973215015289),
            "52" : CLLocationCoordinate2D(latitude: 39.443872756244048, longitude: -8.5720735291832),
            "63" : CLLocationCoordinate2D(latitude: 39.142343184299904, longitude: -8.122916725033491),
            "98" : CLLocationCoordinate2D(latitude: 38.957868481785482, longitude: -8.5281109886180104),
            "42" : CLLocationCoordinate2D(latitude: 39.685972972589099, longitude: -7.8943215384760776),
            "19" : CLLocationCoordinate2D(latitude: 39.491185961716184, longitude: -8.1264358240181309),
            "89" : CLLocationCoordinate2D(latitude: 39.471995196439082, longitude: -8.238429916872775),
            "56" : CLLocationCoordinate2D(latitude: 39.604707280833907, longitude: -9.084805079546129),
            "71" : CLLocationCoordinate2D(latitude: 39.64604772705394,  longitude: -8.2414197472173782),
            "75" : CLLocationCoordinate2D(latitude: 39.863475706702815, longitude: -7.9870358065759035),
            "5"  : CLLocationCoordinate2D(latitude: 39.519658091811749, longitude: -7.6526029780911529),
            "23" : CLLocationCoordinate2D(latitude: 39.547851503426614, longitude: -8.8468441553441437),
            "69" : CLLocationCoordinate2D(latitude: 39.194390716317997, longitude: -8.8637818114092966),
            "24" : CLLocationCoordinate2D(latitude: 39.526049935756987, longitude: -8.9178165592120138),
            "2"  : CLLocationCoordinate2D(latitude: 39.53376484429981,  longitude: -8.1598328734771428),
            "3"  : CLLocationCoordinate2D(latitude: 39.821875581743228, longitude: -7.4908799022149992),
            "27" : CLLocationCoordinate2D(latitude: 39.890334042334757, longitude: -8.5523417138209936),
            "90" : CLLocationCoordinate2D(latitude: 39.27050273853547,  longitude: -8.2013482922915841),
            "80" : CLLocationCoordinate2D(latitude: 40.160101464692474, longitude: -8.5989326985610717),
            "36" : CLLocationCoordinate2D(latitude: 39.359527820289628, longitude: -7.9553314679126288),
            "1"  : CLLocationCoordinate2D(latitude: 39.45852152121617,  longitude: -8.4326973655582833),
            "64" : CLLocationCoordinate2D(latitude: 39.231550950580299, longitude: -8.1732885956591019),
            "13" : CLLocationCoordinate2D(latitude: 39.569214168186676, longitude: -8.2552851484483938),
            "93" : CLLocationCoordinate2D(latitude: 39.19986881519165,  longitude: -7.6594490610166304),
            "100": CLLocationCoordinate2D(latitude: 39.378463397112711, longitude: -8.8559499961882011),
            "61" : CLLocationCoordinate2D(latitude: 39.387724476853379, longitude: -8.0423520923526723),
            "58" : CLLocationCoordinate2D(latitude: 39.650988449081183, longitude: -7.6737269760254208),
            "73" : CLLocationCoordinate2D(latitude: 39.915554052904071, longitude: -8.1463908949753829),
            "14" : CLLocationCoordinate2D(latitude: 39.58408086956527,  longitude: -8.2633954187357688),
            "18" : CLLocationCoordinate2D(latitude: 39.475641355044672, longitude: -8.1321445834334156),
            "29" : CLLocationCoordinate2D(latitude: 39.922214239938398, longitude: -8.9498860387266461),
            "37" : CLLocationCoordinate2D(latitude: 39.676644092851461, longitude: -7.5290755272590388),
            "74" : CLLocationCoordinate2D(latitude: 39.85043306624911,  longitude: -8.3156344128573494)
        ]
    }
}
