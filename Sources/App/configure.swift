import Leaf
import Vapor
import Redis

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
    var task: UpcomingFlightsUpdateTask{
        get {
            return self.storage[TaskKey.self]!
        }
        set {
            self.storage[TaskKey.self] = newValue
        }
    }
}

private struct DatabaseManagerKey: StorageKey {
    typealias Value = DatabaseManager
}

private struct RedisManagerKey: StorageKey {
    typealias Value = RedisManager
}

private struct TaskKey: StorageKey {
    typealias Value = UpcomingFlightsUpdateTask
}

final class UpcomingFlightsUpdateTask {
    private var timer: Timer?
    private let database: DatabaseManager
    private let redis: RedisManager

    init(databaseManager: DatabaseManager, redisManager: RedisManager) {
        database = databaseManager
        redis = redisManager
        // Schedule the timer to run your task every minute
        timer = Timer.scheduledTimer(
            timeInterval: 60.0,  // 60 seconds, i.e., 1 minute
            target: self,
            selector: #selector(runTask),
            userInfo: nil,
            repeats: true
        )
    }

    @objc func runTask() {
        let flights = database.getUpcomingFlights()
        let upcomingFlights = redis.flightsToUpcomingFlights(flights)
        do {
            try redis.pushUpcomingFlights(upcomingFlights)
            print("UpcomingFlightsUpdateTask is running at \(Date())")
        } catch {
            print("Failed to run UpcomingFlightsUpdateTask at \(Date())\n\(error)")
        }
    }

    deinit {
        // Invalidate the timer when the object is deallocated
        timer?.invalidate()
        timer = nil
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
    app.redis.configuration = try RedisConfiguration(hostname: "localhost", port: 6379)
    app.redisManager = RedisManager(app.redis)
    try app.redisManager.pushUpcomingFlights(
        app.redisManager.flightsToUpcomingFlights(
            app.databaseManager.getUpcomingFlights()
        )
    )
    
    app.task = UpcomingFlightsUpdateTask(databaseManager: app.databaseManager, redisManager: app.redisManager)
    app.task.runTask()
    
    // Configures cookie value creation.
    app.sessions.configuration.cookieFactory = { sessionID in
        .init(string: sessionID.string, isSecure: true)
    }
    app.sessions.use(.redis)
    app.middleware.use(app.sessions.middleware)
    
    // register routes
    try routes(app)
}
