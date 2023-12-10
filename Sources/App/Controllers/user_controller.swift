import Foundation
import Vapor

class UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let user_routes = routes.grouped("user")
        user_routes.get(use: indexHandler)
        user_routes.post("register", use: registerHandler)
        user_routes.post("data", use: getUserData)
        user_routes.post("buy", use: buyTicket)
        user_routes.post("info", use: getInfo)
    }
    
    func registerHandler(_ req: Request) throws -> EventLoopFuture<View> {
        guard let user = try? req.content.decode(User.self) else {
            throw Abort(.badRequest)
        }
        
        print(user)
        do {
            try req.application.databaseManager.addUser(newUser: user)
        } catch {
            throw Abort(.badRequest)
        }
        return req.view.render("DataTemplates/confirmation", ["email": user.email])
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
    
    func buyTicket(_ req: Request) throws -> EventLoopFuture<View> {
        struct BuyData: Content {
            let email: String
            let flightId: Int
        }
        
        guard let buyData = try? req.content.decode(BuyData.self) else {
            throw Abort(.expectationFailed)
        }
        print(buyData)
        try req.application.databaseManager.addTicket(loginData: LoginData(email: buyData.email), flightId: buyData.flightId)
        return req.view.render("DataTemplates/confirmation", ["email": "Confirmed buy"])
    }
    
    func getInfo(_ req: Request) throws -> EventLoopFuture<View> {
        guard let loginData = try? req.content.decode(LoginData.self) else {
            throw Abort(.expectationFailed)
        }
        print(loginData)
        let userData = try req.application.databaseManager.getUserData(loginData: loginData)
        return req.view.render("DataTemplates/user", userData.self)
    }

    func indexHandler(_ req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("profile")
    }
}
