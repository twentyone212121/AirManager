import Leaf
import Vapor
import Redis
import QueuesRedisDriver
import Queues

extension Application {
    var databaseManager: DatabaseManager {
        get {
            return self.storage[DatabaseManagerKey.self]!
        }
        set {
            self.storage[DatabaseManagerKey.self] = newValue
        }
    }
    var redisManager: RedisManager {
        get {
            return self.storage[RedisManagerKey.self]!
        }
        set {
            self.storage[RedisManagerKey.self] = newValue
        }
    }
}

private struct DatabaseManagerKey: StorageKey {
    typealias Value = DatabaseManager
}

private struct RedisManagerKey: StorageKey {
    typealias Value = RedisManager
}

final class UpcomingFlightsUpdateJob: ScheduledJob {
    private let database: DatabaseManager
    private let redis: RedisManager
    
    func run(context: Queues.QueueContext) -> EventLoopFuture<Void> {
        return updateUpcomingFlights().flatMap {_ in
            context.eventLoop.makeSucceededVoidFuture()
        }
    }

    init(databaseManager: DatabaseManager, redisManager: RedisManager) {
        database = databaseManager
        redis = redisManager
        print("Timer set")
    }

    func updateUpcomingFlights() -> EventLoopFuture<Int> {
        let flights = database.getUpcomingFlights()
        print("UpcomingFlightsUpdateTask is running at \(Date())")
        let upcomingFlights = redis.flightsToUpcomingFlights(flights)
        return try! redis.pushUpcomingFlights(upcomingFlights)
    }
}

// configures your application
public func configure(_ app: Application) async throws {
    app.views.use(.leaf)
    app.leaf.tags["formatDouble"] = FormatDoubleTag()

    // Serves files from `Public/` directory
    let fileMiddleware = FileMiddleware(
        publicDirectory: app.directory.publicDirectory
    )
    app.middleware.use(fileMiddleware)
    
    app.databaseManager = DatabaseManager()
    let redisConfig = try RedisConfiguration(hostname: "localhost", port: 6379, pool: .init(connectionRetryTimeout: .seconds(10)))
    app.redis.configuration = redisConfig
    app.redisManager = RedisManager(app.redis)
    
    // configure queue and add job to update upcomingFlights
    app.queues.use(.redis(redisConfig))
    let job = UpcomingFlightsUpdateJob(databaseManager: app.databaseManager, redisManager: app.redisManager)
    try await job.updateUpcomingFlights().get()
    app.queues.schedule(job)
        .minutely()
        .at(.init(integerLiteral: 59))
    try app.queues.startScheduledJobs()
    
    // Configures cookie value creation.
    app.sessions.configuration.cookieFactory = { sessionID in
        .init(string: sessionID.string, isSecure: true)
    }
    app.sessions.use(.redis)
    app.middleware.use(app.sessions.middleware)
    
    // register routes
    try routes(app)
}
