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
      locations["\(self.locations.count)"] = location
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
               let left = "\(source[mod: 1].str6),\(source[mod: 0].str6)"
               let right = "\(destination[mod: 1].str6),\(destination[mod: 0].str6)"
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
#if compiler(>=5.1)
      if #available(iOS 13.0, *) { overrideUserInterfaceStyle = .light }
#endif
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
//      var locsArray = Array(CLLocationCoordinate2D.locs())
//      locsArray.shuffle()
//      var locs = [String : CLLocationCoordinate2D]()
//      for (key, value) in locsArray {
//         locs[key] = value
//      }
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
      var dictLoc = [String : Any]()
      for _loc in self.locations { dictLoc["\(_loc.key)"] = _loc.value }
      self.generator = Generator(organsNameContent: dictLoc, muscles: { body, isLinear -> Body in
         for o1 in body {
            for o2 in body {
               guard o1 != o2 else {
                  continue
               }
               guard let p1 = o1.content as? CLLocationCoordinate2D,
                     let p2 = o2.content as? CLLocationCoordinate2D
               else {
                  continue
               }
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
         locations.removeAll()
         DispatchQueue.main.async {
            self.clearBtn.setTitle(txt, for: .normal)
            self.generationLbl.text = "Locations: \(self.locations.count)"
            self.mapView.removeAnnotations(self.mapView.annotations)
            self.mapView.removeOverlays(self.mapView.overlays)
         }
      } else {
         clearBtn.setTitle(ok, for: .normal)
         DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            self.clearBtn.setTitle(txt, for: .normal)
            for loc in self.locations {
               let coord = loc.value
               print("\"\(loc.key)\"  : CLLocationCoordinate2D(latitude: \(coord.latitude), longitude: \(coord.longitude)),")
            }
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
      return "\(self.latitude.str6),\(self.longitude.str6)"
   }
   static func locs() -> [String : CLLocationCoordinate2D] {
      return [
         "0"  : CLLocationCoordinate2D(latitude: 39.474405474571455, longitude: -8.473226183870784),
         "1"  : CLLocationCoordinate2D(latitude: 39.47424164997911, longitude: -8.473200258992787),
         "10"  : CLLocationCoordinate2D(latitude: 39.54206622012302, longitude: -8.491676517757503),
         "12"  : CLLocationCoordinate2D(latitude: 39.56221255867336, longitude: -8.49251558976097),
         "13"  : CLLocationCoordinate2D(latitude: 39.57334248221376, longitude: -8.492764114917838),
         "14"  : CLLocationCoordinate2D(latitude: 39.57449884432807, longitude: -8.498306339238217),
         "15"  : CLLocationCoordinate2D(latitude: 39.580525542528584, longitude: -8.506137500262573),
         "2"  : CLLocationCoordinate2D(latitude: 39.47523740049416, longitude: -8.473344962127891),
         "20"  : CLLocationCoordinate2D(latitude: 39.577096906278825, longitude: -8.541720169844227),
         "21"  : CLLocationCoordinate2D(latitude: 39.558418635361356, longitude: -8.549956877007224),
         "22"  : CLLocationCoordinate2D(latitude: 39.55051782647272, longitude: -8.552188450454304),
         "23"  : CLLocationCoordinate2D(latitude: 39.53486663708502, longitude: -8.551899117607986),
         "26"  : CLLocationCoordinate2D(latitude: 39.482336794690276, longitude: -8.531947122750905),
         "27"  : CLLocationCoordinate2D(latitude: 39.47244343866183, longitude: -8.525083498544316),
         "28"  : CLLocationCoordinate2D(latitude: 39.461608131421265, longitude: -8.52111301017002),
         "29"  : CLLocationCoordinate2D(latitude: 39.449776675916894, longitude: -8.514998444679097),
         "3"  : CLLocationCoordinate2D(latitude: 39.4761826783068, longitude: -8.473609237180252),
         "30"  : CLLocationCoordinate2D(latitude: 39.446364956782745, longitude: -8.503596908000986),
         "31"  : CLLocationCoordinate2D(latitude: 39.4433498151923, longitude: -8.491457653920076),
         "11"  : CLLocationCoordinate2D(latitude: 39.44785405884006, longitude: -8.481683921259567),
         "24"  : CLLocationCoordinate2D(latitude: 39.45135266251292, longitude: -8.478016208572202),
         "25"  : CLLocationCoordinate2D(latitude: 39.45269283355514, longitude: -8.476935444171943),
         "19"  : CLLocationCoordinate2D(latitude: 39.4653457017798, longitude: -8.470594136720688),
         "18"  : CLLocationCoordinate2D(latitude: 39.466833122948444, longitude: -8.471053738078806),
         "17"  : CLLocationCoordinate2D(latitude: 39.47065302346593, longitude: -8.473020082960536),
         "4"  : CLLocationCoordinate2D(latitude: 39.48567723258337, longitude: -8.470199666189142),
         "16"  : CLLocationCoordinate2D(latitude: 39.47284452276404, longitude: -8.472994218713682),
         "5"  : CLLocationCoordinate2D(latitude: 39.49445244186788, longitude: -8.47017240937698),
         "6"  : CLLocationCoordinate2D(latitude: 39.50625147531509, longitude: -8.469542170348477),
         "7"  : CLLocationCoordinate2D(latitude: 39.523037267043144, longitude: -8.471293331776463),
         "8"  : CLLocationCoordinate2D(latitude: 39.52618761228522, longitude: -8.470522946770837),
         "9"  : CLLocationCoordinate2D(latitude: 39.53450312956557, longitude: -8.476535985439497),
//         "0"  : CLLocationCoordinate2D(latitude: 39.462738688373264, longitude: -8.468041881437557),
//         "1"  : CLLocationCoordinate2D(latitude: 39.45852152121617,  longitude: -8.432697365558283),
//         "2"  : CLLocationCoordinate2D(latitude: 39.41889971905721,  longitude: -8.415302963336245),
//         "3"  : CLLocationCoordinate2D(latitude: 39.44387275624405,  longitude: -8.5720735291832),
//         "4"  : CLLocationCoordinate2D(latitude: 39.53776009862244,  longitude: -8.383517507196927),
//         "5"  : CLLocationCoordinate2D(latitude: 39.47633196634311,  longitude: -8.337712693277354),
//         "6"  : CLLocationCoordinate2D(latitude: 39.51520446832674,  longitude: -8.617771572280645),
//         "7"  : CLLocationCoordinate2D(latitude: 39.41570466946183,  longitude: -8.311820960093968),
//         "8"  : CLLocationCoordinate2D(latitude: 39.58825664052702,  longitude: -8.513577314288483),
//         "9"  : CLLocationCoordinate2D(latitude: 39.60220996532891,  longitude: -8.414542392287103),
//         "10" : CLLocationCoordinate2D(latitude: 39.57206910721325,  longitude: -8.601175411781242),
//         "11" : CLLocationCoordinate2D(latitude: 39.36217721509644,  longitude: -8.621831370723442),
//         "12" : CLLocationCoordinate2D(latitude: 39.32923426346551,  longitude: -8.577143707668114),
//         "13" : CLLocationCoordinate2D(latitude: 39.554609239153564, longitude: -8.28529009653488),
//         "14" : CLLocationCoordinate2D(latitude: 39.38411374736603,  longitude: -8.661481002779254),
//         "15" : CLLocationCoordinate2D(latitude: 39.4578545030802,   longitude: -8.24617057821925),
//         "16" : CLLocationCoordinate2D(latitude: 39.47199519643908,  longitude: -8.238429916872775),
//         "17" : CLLocationCoordinate2D(latitude: 39.303110513345416, longitude: -8.573018643069986),
//         "18" : CLLocationCoordinate2D(latitude: 39.3262014490204,   longitude: -8.295392630284965),
//         "19" : CLLocationCoordinate2D(latitude: 39.27794764968479,  longitude: -8.542027790446895),
//         "20" : CLLocationCoordinate2D(latitude: 39.569214168186676, longitude: -8.255285148448394),
//         "21" : CLLocationCoordinate2D(latitude: 39.58408086956527,  longitude: -8.263395418735769),
//         "22" : CLLocationCoordinate2D(latitude: 39.4628254296463,   longitude: -8.197704502511016),
//         "23" : CLLocationCoordinate2D(latitude: 39.65629288408891,  longitude: -8.579408370860904),
//         "24" : CLLocationCoordinate2D(latitude: 39.363811016100755, longitude: -8.223780054698409),
//         "25" : CLLocationCoordinate2D(latitude: 39.60718716602935,  longitude: -8.255884526601847),
//         "26" : CLLocationCoordinate2D(latitude: 39.538376216715164, longitude: -8.756109241075677),
//         "27" : CLLocationCoordinate2D(latitude: 39.53376484429981,  longitude: -8.159832873477143),
//         "28" : CLLocationCoordinate2D(latitude: 39.64604772705394,  longitude: -8.241419747217378),
//         "29" : CLLocationCoordinate2D(latitude: 39.21374016073838,  longitude: -8.399816276598102),
//         "30" : CLLocationCoordinate2D(latitude: 39.47564135504467,  longitude: -8.132144583433416),
//         "31" : CLLocationCoordinate2D(latitude: 39.491185961716184, longitude: -8.126435824018131),
//         "32" : CLLocationCoordinate2D(latitude: 39.20309885502073,  longitude: -8.553772642899503),
//         "33" : CLLocationCoordinate2D(latitude: 39.351374003432426, longitude: -8.13950361893248),
//         "34" : CLLocationCoordinate2D(latitude: 39.66002813353916,  longitude: -8.722014093862839),
//         "35" : CLLocationCoordinate2D(latitude: 39.724054025655306, longitude: -8.338354556013002),
//         "36" : CLLocationCoordinate2D(latitude: 39.64299730460701,  longitude: -8.190615669468059),
//         "37" : CLLocationCoordinate2D(latitude: 39.27050273853547,  longitude: -8.201348292291584),
//         "38" : CLLocationCoordinate2D(latitude: 39.75000325143441,  longitude: -8.58850829015833),
//         "39" : CLLocationCoordinate2D(latitude: 39.547851503426614, longitude: -8.846844155344144),
//         "40" : CLLocationCoordinate2D(latitude: 39.78655954316673,  longitude: -8.465289939392136),
//         "41" : CLLocationCoordinate2D(latitude: 39.73039007179139,  longitude: -8.231256667849749),
//         "42" : CLLocationCoordinate2D(latitude: 39.2315509505803,   longitude: -8.173288595659102),
//         "43" : CLLocationCoordinate2D(latitude: 39.38772447685338,  longitude: -8.042352092352672),
//         "44" : CLLocationCoordinate2D(latitude: 39.76170757567968,  longitude: -8.235792961436943),
//         "45" : CLLocationCoordinate2D(latitude: 39.52604993575699,  longitude: -8.917816559212014),
//         "46" : CLLocationCoordinate2D(latitude: 39.237783380217365, longitude: -8.833647665100187),
//         "47" : CLLocationCoordinate2D(latitude: 39.140178254652,    longitude: -8.686221568093885),
//         "48" : CLLocationCoordinate2D(latitude: 39.82415847013067,  longitude: -8.577810826366147),
//         "49" : CLLocationCoordinate2D(latitude: 39.551243490039155, longitude: -7.994742553363125),
//         "50" : CLLocationCoordinate2D(latitude: 39.08328061287531,  longitude: -8.405829796703614),
//         "51" : CLLocationCoordinate2D(latitude: 39.740636678372084, longitude: -8.810301158882766),
//         "52" : CLLocationCoordinate2D(latitude: 39.70159417873742,  longitude: -8.069942414314596),
//         "53" : CLLocationCoordinate2D(latitude: 39.495563647096105, longitude: -7.956578273044528),
//         "54" : CLLocationCoordinate2D(latitude: 39.85043306624911,  longitude: -8.31563441285735),
//         "55" : CLLocationCoordinate2D(latitude: 39.194390716318,    longitude: -8.863781811409297),
//         "56" : CLLocationCoordinate2D(latitude: 39.87101325454924,  longitude: -8.443023912352999),
//         "57" : CLLocationCoordinate2D(latitude: 39.35952782028963,  longitude: -7.955331467912629),
//         "58" : CLLocationCoordinate2D(latitude: 39.10852305680913,  longitude: -8.738960323394451),
//         "59" : CLLocationCoordinate2D(latitude: 39.463372577537996, longitude: -7.9356045571241225),
//         "60" : CLLocationCoordinate2D(latitude: 39.245804819189686, longitude: -8.009089511229234),
//         "61" : CLLocationCoordinate2D(latitude: 39.142343184299904, longitude: -8.122916725033491),
//         "62" : CLLocationCoordinate2D(latitude: 39.635004018709026, longitude: -7.963111417177856),
//         "63" : CLLocationCoordinate2D(latitude: 39.89033404233476,  longitude: -8.552341713820994),
//         "64" : CLLocationCoordinate2D(latitude: 39.80456853754836,  longitude: -8.098601603961527),
//         "65" : CLLocationCoordinate2D(latitude: 39.03327362152726,  longitude: -8.634706960067945),
//         "66" : CLLocationCoordinate2D(latitude: 39.06621195962455,  longitude: -8.756563439993101),
//         "67" : CLLocationCoordinate2D(latitude: 39.309232137479,    longitude: -7.910181935024809),
//         "68" : CLLocationCoordinate2D(latitude: 39.52961442794293,  longitude: -7.854972661165135),
//         "69" : CLLocationCoordinate2D(latitude: 39.84852257982803,  longitude: -8.839584185008789),
//         "70" : CLLocationCoordinate2D(latitude: 39.49471235856058,  longitude: -7.834682991543161),
//         "71" : CLLocationCoordinate2D(latitude: 39.6859729725891,   longitude: -7.894321538476078),
//         "72" : CLLocationCoordinate2D(latitude: 39.60470728083391,  longitude: -9.084805079546129),
//         "73" : CLLocationCoordinate2D(latitude: 39.092075197462776, longitude: -8.034669383288986),
//         "74" : CLLocationCoordinate2D(latitude: 39.95159244509341,  longitude: -8.628988261871086),
//         "75" : CLLocationCoordinate2D(latitude: 39.02488214740811,  longitude: -8.793454590441911),
//         "76" : CLLocationCoordinate2D(latitude: 38.95786848178548,  longitude: -8.52811098861801),
//         "77" : CLLocationCoordinate2D(latitude: 39.91555405290407,  longitude: -8.146390894975383),
//         "78" : CLLocationCoordinate2D(latitude: 39.32002276299443,  longitude: -7.809421143085558),
//         "79" : CLLocationCoordinate2D(latitude: 39.714838150204,    longitude: -7.863629914267477),
//         "80" : CLLocationCoordinate2D(latitude: 39.863475706702815, longitude: -7.9870358065759035),
//         "81" : CLLocationCoordinate2D(latitude: 40.01565636799933,  longitude: -8.534556920860581),
//         "82" : CLLocationCoordinate2D(latitude: 39.037132636756155, longitude: -8.93346969167331),
//         "83" : CLLocationCoordinate2D(latitude: 39.938440137788604, longitude: -8.862444530281579),
//         "84" : CLLocationCoordinate2D(latitude: 39.874107269237186, longitude: -8.971976510985456),
//         "85" : CLLocationCoordinate2D(latitude: 39.777882835792866, longitude: -7.856647154143843),
//         "86" : CLLocationCoordinate2D(latitude: 40.04504511186727,  longitude: -8.453899058255246),
//         "87" : CLLocationCoordinate2D(latitude: 39.9222142399384,   longitude: -8.949886038726646),
//         "88" : CLLocationCoordinate2D(latitude: 39.05699817955792,  longitude: -7.891397321501529),
//         "89" : CLLocationCoordinate2D(latitude: 39.51965809181175,  longitude: -7.652602978091153),
//         "90" : CLLocationCoordinate2D(latitude: 39.65098844908118,  longitude: -7.673726976025421),
//         "91" : CLLocationCoordinate2D(latitude: 39.19986881519165,  longitude: -7.65944906101663),
//         "92" : CLLocationCoordinate2D(latitude: 39.78603953194519,  longitude: -7.67245762522316),
//         "93" : CLLocationCoordinate2D(latitude: 40.160101464692474, longitude: -8.598932698561072),
//         "94" : CLLocationCoordinate2D(latitude: 39.751303529829215, longitude: -7.621065477648415),
//         "95" : CLLocationCoordinate2D(latitude: 40.17845855551204,  longitude: -8.696718169494005),
//         "96" : CLLocationCoordinate2D(latitude: 39.67664409285146,  longitude: -7.529075527259039),
//         "97" : CLLocationCoordinate2D(latitude: 39.64845954391521,  longitude: -7.498546013863404),
//         "98" : CLLocationCoordinate2D(latitude: 39.2914597224331,   longitude: -7.429587823647438),
//         "99" : CLLocationCoordinate2D(latitude: 39.82187558174323,  longitude: -7.490879902214999), 
      ]
   }
}
