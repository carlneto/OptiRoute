import MapKit

struct GoogleMapsMatrix {
   static func get(locations: [CLLocationCoordinate2D], model: @escaping (Self?) -> Void) {
      let url = URL(string: "https://maps.googleapis.com/maps/api/distancematrix/json?origins=Washington,DC&destinations=New+York+City,NY&key=AIzaSyBmDh4Ku2gitg3fZwip6jPJEg5rJcOGXZo")!
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
      //[9.70093,48.477473],[9.207916,49.153868],[37.573242,55.801281],[115.663757,38.106467]
      request.httpBody = try? JSONSerialization.data(withJSONObject: ["locations" : locations])
      let task = URLSession.shared.dataTask(with: request) { data, response, error in
         if let response, let data {
            print(response, data)
            //print(String(decoding: data, as: UTF8.self))
            //let jsonDecoder = JSONDecoder()
            //let responseModel = try? jsonDecoder.decode(MapQuestMatrix.self, from: data)
            //model(responseModel)
         } else {
            print(error ?? "error!?!")
         }
      }
      task.resume()
   }
}
