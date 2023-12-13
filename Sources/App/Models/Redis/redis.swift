import Redis

class RedisManager {
    init(_ client: RedisClient) {
        do {
            client.set("beba", to: "1234")
            let value = try client.get("beba", as: String.self).wait()
            print(value)
        } catch {
            print(error)
        }
    }
}