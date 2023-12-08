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
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.views.use(.leaf)

    // Serves files from `Public/` directory
    let fileMiddleware = FileMiddleware(
        publicDirectory: app.directory.publicDirectory
    )
    app.middleware.use(fileMiddleware)
    
//    app.services.register { _ -> DatabaseManager in
//            return DatabaseManager()
//        }
    app.databaseManager = DatabaseManager()

    // register routes
    try routes(app)
}
