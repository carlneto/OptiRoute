import MapKit

struct Place: Codable, Equatable {
    let distance: Double?
    let name: String?
    let coordinate: [Double]?
    enum CodingKeys: String, CodingKey {
        case distance = "distance"
        case name = "name"
        case coordinate = "location"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        distance = try values.decodeIfPresent(Double.self, forKey: .distance)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        coordinate = try values.decodeIfPresent([Double].self, forKey: .coordinate)
    }
}
struct MapBoxMatrix: Codable {
    let code: String?
    let durations: [[Double]]?
    let destinations: [Place]?
    let sources: [Place]?
    enum CodingKeys: String, CodingKey {
        case code = "code"
        case durations = "durations"
        case destinations = "destinations"
        case sources = "sources"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        code = try values.decodeIfPresent(String.self, forKey: .code)
        durations = try values.decodeIfPresent([[Double]].self, forKey: .durations)
        destinations = try values.decodeIfPresent([Place].self, forKey: .destinations)
        sources = try values.decodeIfPresent([Place].self, forKey: .sources)
    }
    static func get(locations: [CLLocationCoordinate2D], model: @escaping ([CLLocationCoordinate2D], Self?) -> Void) {
        var locs = locations
        guard !locs.isEmpty else {
            fatalError()
        }
        let loc1 = locs.removeFirst()
        var urlString = "https://api.mapbox.com/directions-matrix/v1/mapbox/driving/\(loc1.latitude),\(loc1.longitude)"
        for loc in locs {
            urlString += ";\(loc.latitude),\(loc.longitude)"
        }
        urlString += "?&access_token=pk.eyJ1IjoiY2FybG5ldG8iLCJhIjoiY2s5dHVteHBzMWh5ZDNkcWNpcXdqODNsYSJ9.e13S9tF8WXS0SbmTYwHBDQ"
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let response = response, let data = data {
                print(response)
                print(String(decoding: data, as: UTF8.self))
                let jsonDecoder = JSONDecoder()
                let responseModel = try? jsonDecoder.decode(MapBoxMatrix.self, from: data)
                model(locations, responseModel)
            } else {
                print(error ?? "error!?!")
            }
        }
        task.resume()
    }
}
