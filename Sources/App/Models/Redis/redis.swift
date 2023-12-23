import Foundation
import Redis
import Vapor

struct UpcomingFlight: Content, RESPValueConvertible {
    init?(fromRESP value: RediStack.RESPValue) {
        self = try! JSONDecoder().decode(UpcomingFlight.self, from: value.byteBuffer!)
    }
    
    func convertedToRESPValue() -> RediStack.RESPValue {
        
        let encoder = JSONEncoder()
        let value = try! encoder.encodeAsByteBuffer(self, allocator: ByteBufferAllocator())
        return .bulkString(value)
    }
    
    init(time: Date, number: Int, from: String, to: String) {
        self.time = time
        self.number = number
        self.from = from
        self.to = to
    }
    
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
            $0.time < $1.time
        }
    }
    
    func pushUpcomingFlights(_ flights: [UpcomingFlight]) throws -> EventLoopFuture<Int> {
        print("Pushing values: ")
        return redis.delete(upcomingFlights).flatMap {_ in
            return self.redis.rpush(flights, into: self.upcomingFlights)
        }
    }
    
    func getUpcomingFlights() -> EventLoopFuture<[UpcomingFlight?]> {
        return redis.lrange(
            from: upcomingFlights,
            fromIndex: 0,
            as: UpcomingFlight.self)
    }
}
