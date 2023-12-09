import Foundation
import Vapor

class UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let user_routes = routes.grouped("user")
        user_routes.get(use: indexHandler)
        user_routes.post(use: registerHandler)
        user_routes.post("data", use: getUserData)
    }
    
    func registerHandler(_ req: Request) throws -> Response {
        guard let user = try? req.content.decode(User.self) else {
            throw Abort(.badRequest)
        }
         
        print(user)
        do {
            try req.application.databaseManager.addUser(newUser: user)
        } catch {
            throw Abort(.badRequest)
        }
        return Response(status: .ok)
    }
    
    func getUserData(_ req: Request) throws -> EventLoopFuture<View> {
        guard let loginData = try? req.content.decode(LoginData.self) else {
            throw Abort(.badRequest)
        }
        
        do {
            let user = try req.application.databaseManager.getUserData(loginData: loginData)
            return req.view.render("DataTemplates/userData", ["user": user])
        } catch {
            throw Abort(.badRequest)
        }
    }

    func indexHandler(_ req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("profile")
    }
}
