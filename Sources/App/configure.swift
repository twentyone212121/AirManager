import Leaf
import Vapor

extension Application {
    var databaseManager: DatabaseManager {
        get {
            return self.storage[DatabaseManagerKey.self]!
        }
        set {
            self.storage[DatabaseManagerKey.self] = newValue
        }
    }
}

private struct DatabaseManagerKey: StorageKey {
    typealias Value = DatabaseManager
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
    
    // Configures cookie value creation.
    app.sessions.configuration.cookieFactory = { sessionID in
        .init(string: sessionID.string, isSecure: true)
    }
    app.middleware.use(app.sessions.middleware)
    
    app.databaseManager = DatabaseManager()

    // register routes
    try routes(app)
}
