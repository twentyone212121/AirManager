import Foundation
import Vapor

class UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let user_routes = routes.grouped("user")
        user_routes.get(use: indexHandler)
        user_routes.post("register", use: registerHandler)
        user_routes.get("buy", ":flightId", use: buyTicket)
        user_routes.get("info", use: getInfo)
        user_routes.post("login", use: login)
    }
    
    func registerHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        guard let user = try? req.content.decode(User.self) else {
            throw Abort(.badRequest)
        }
        
        print(user)
        do {
            try req.application.databaseManager.addUser(newUser: user)
        } catch {
            let view = req.view.render("DataTemplates/confirmation", ["text": "You have already registered.", "type": "fail", "to": "/login"])
            let response = view.encodeResponse(for: req)
            return response
        }
        
        let token = user.email
        req.session.data["user"] = token
        
        return req.view.render("DataTemplates/confirmation", ["text": "You have successfully registered under email \(user.email).",
        "type": "success",
        "to": "/profile"]
        ).encodeResponse(for: req)
    }
        
    func buyTicket(_ req: Request) throws -> EventLoopFuture<Response> {
        guard let token = req.session.data["user"] else {
            let view = req.view.render("DataTemplates/confirmation", ["text": "Sign in first.", "type": "fail", "to": "#"])
            let response = view.encodeResponse(for: req)
            return response
        }
        
        // Validate the token and get the associated user
        guard let loginData = req.application.databaseManager.validateTokenAndGetUser(token: token) else {
            let view = req.view.render("DataTemplates/confirmation", ["text": "Sign in first.", "type": "fail", "to": "#"])
            let response = view.encodeResponse(for: req)
            return response
        }
        
        guard let flightId = Int(req.parameters.get("flightId")!) else {
            throw Abort(.expectationFailed)
        }
        print(flightId)
        try req.application.databaseManager.addTicket(loginData: loginData, flightId: flightId)
        return req.view.render("DataTemplates/confirmation", [
            "text": "You bought this flight. Find the ticket in your profile.",
            "type": "success",
            "to": "/profile"
        ]).encodeResponse(for: req)
    }
    
    func getInfo(_ req: Request) throws -> EventLoopFuture<View> {
        guard let token = req.session.data["user"] else {
            // Token not present, user is not authenticated
            return req.eventLoop.future(error: Abort(.unauthorized))
        }
        
        // Validate the token and get the associated user
        guard let loginData = req.application.databaseManager.validateTokenAndGetUser(token: token) else {
            throw Abort(.unauthorized)
        }
        
        print(loginData)
        let userData = try req.application.databaseManager.getUserData(loginData: loginData)
        return req.view.render("DataTemplates/userData", userData.self)
    }

    func indexHandler(_ req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("profile")
    }
    
    func login(_ req: Request) throws -> EventLoopFuture<Response> {
        guard let loginData = try? req.content.decode(LoginData.self) else {
            throw Abort(.expectationFailed)
        }
        
        guard let userType = req.application.databaseManager.verifyLogin(loginData: loginData) else {
            return req.view.render("DataTemplates/confirmation", ["text": "Incorrect login or password.", "type": "fail", "to": "#"]).encodeResponse(for: req)
        }
        
        let token = loginData.email
        
        switch userType {
        case UserType.manager:
            req.session.data["manager"] = token
            return req.view.render("DataTemplates/confirmation", ["text": "Confirmed manager login.", "type": "success", "to": "/"]).encodeResponse(for: req)
        case UserType.user:
            req.session.data["user"] = token
            return req.view.render("DataTemplates/confirmation", ["text": "Confirmed user login.", "type": "success", "to": "/"]).encodeResponse(for: req)
        }
    }
}
