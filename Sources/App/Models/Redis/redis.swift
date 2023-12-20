import Foundation
import Redis

struct UpcomingFlight: Encodable {
    let time: Date
    let number: Int
    let from: String
    let to: String
}

class RedisManager {
    let redis: RedisClient
    let upcomingFlights = RedisKey("upcomingFlights")
    
    init(_ client: RedisClient) {
        redis = client
    }
    
    func flightsToUpcomingFlights(_ flights: [Flight]) -> [UpcomingFlight] {
        flights.map {
            UpcomingFlight(
                time: $0.fromDate,
                number: $0.number,
                from: $0.fromIata,
                to: $0.toIata
            )
        }.sorted {
            $0.from < $1.from
        }
    }
    
    func pushUpcomingFlights(_ flights: [UpcomingFlight]) throws {
        let encoder = JSONEncoder()
        let flightsData = try flights.map {
            try encoder.encode($0).base64EncodedString()
        }
        let result = try redis.rpush(flightsData, into: upcomingFlights).wait();
        print("Result after pushing upcoming flights: \(result)")
    }
}
