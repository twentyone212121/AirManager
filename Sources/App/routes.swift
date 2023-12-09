import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: SearchController())
    try app.register(collection: PageController())
    try app.register(collection: UserController())
    try app.register(collection: ManagerController())
}
