import Foundation

struct Location: Codable, Equatable {
    let coordinate: [Double]?
    let snapped_distance: Double?
    enum CodingKeys: String, CodingKey {
        case coordinate = "location"
        case snapped_distance = "snapped_distance"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        coordinate = try values.decodeIfPresent([Double].self, forKey: .coordinate)
        snapped_distance = try values.decodeIfPresent(Double.self, forKey: .snapped_distance)
    }
    var str: String {
        guard let location = coordinate, location.count == 2 else { return "" }
        let left = location[mod: 1], right = location[mod: 0]
        return "\(left.zeros(6)),\(right.zeros(6))"
    }
    static func == (lhs: Location, rhs: Location) -> Bool {
        guard lhs.snapped_distance == rhs.snapped_distance else { return false }
        guard lhs.coordinate == rhs.coordinate else { return false }
        return true
    }
}
struct Engine: Codable {
    let version: String?
    let build_date: String?
    let graph_date: String?
    enum CodingKeys: String, CodingKey {
        case version = "version"
        case build_date = "build_date"
        case graph_date = "graph_date"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        version = try values.decodeIfPresent(String.self, forKey: .version)
        build_date = try values.decodeIfPresent(String.self, forKey: .build_date)
        graph_date = try values.decodeIfPresent(String.self, forKey: .graph_date)
    }
}
struct Metadata: Codable {
    let attribution: String?
    let service: String?
    let timestamp: Int?
    let query: Query?
    let engine: Engine?
    enum CodingKeys: String, CodingKey {
        case attribution = "attribution"
        case service = "service"
        case timestamp = "timestamp"
        case query = "query"
        case engine = "engine"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        attribution = try values.decodeIfPresent(String.self, forKey: .attribution)
        service = try values.decodeIfPresent(String.self, forKey: .service)
        timestamp = try values.decodeIfPresent(Int.self, forKey: .timestamp)
        query = try values.decodeIfPresent(Query.self, forKey: .query)
        engine = try values.decodeIfPresent(Engine.self, forKey: .engine)
    }
}
struct Query: Codable {
    let locations: [[Double]]?
    let profile: String?
    let responseType: String?
    enum CodingKeys: String, CodingKey {
        case locations = "locations"
        case profile = "profile"
        case responseType = "responseType"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        locations = try values.decodeIfPresent([[Double]].self, forKey: .locations)
        profile = try values.decodeIfPresent(String.self, forKey: .profile)
        responseType = try values.decodeIfPresent(String.self, forKey: .responseType)
    }
}
struct ORMatrix: Codable {
    let durations: [[Double]]?
    let destinations: [Location]?
    let sources: [Location]?
    let metadata: Metadata?
    enum CodingKeys: String, CodingKey {
        case durations = "durations"
        case destinations = "destinations"
        case sources = "sources"
        case metadata = "metadata"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        durations = try values.decodeIfPresent([[Double]].self, forKey: .durations)
        destinations = try values.decodeIfPresent([Location].self, forKey: .destinations)
        sources = try values.decodeIfPresent([Location].self, forKey: .sources)
        metadata = try values.decodeIfPresent(Metadata.self, forKey: .metadata)
    }
    static func get(locations: [[Double]], model: @escaping (Self?) -> Void) {
        let url = URL(string: "https://api.openrouteservice.org/v2/matrix/driving-car")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8", forHTTPHeaderField: "Accept")
        request.addValue("5b3ce3597851110001cf62482963c96e61964bb2a3e90f7af189aa21", forHTTPHeaderField: "Authorization")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        //[9.70093,48.477473],[9.207916,49.153868],[37.573242,55.801281],[115.663757,38.106467]
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["locations" : locations])
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
          if let response = response, let data = data {
            print(response)
            //print(String(decoding: data, as: UTF8.self))
            let jsonDecoder = JSONDecoder()
            let responseModel = try? jsonDecoder.decode(ORMatrix.self, from: data)
            model(responseModel)
          } else {
            print(error ?? "error!?!")
          }
        }
        task.resume()
    }
}
