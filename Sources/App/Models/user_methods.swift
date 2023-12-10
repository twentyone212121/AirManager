import Foundation
import SQLite
import SQLite3
import Vapor

struct User: Content {
    let email: String
    let password: String
    let fullName: String
    let passportNumber: String
    let phoneNumber: Int
    let gender: String
}

struct UserData: Content {
    let fullName: String
    let passportNumber: String
    let phoneNumber: Int
    let email: String
    let gender: String
    let flights: [Flight]
}

struct LoginData: Content {
    let email: String
    let password: String
}

struct Manager: Content {
    let email: String
    let password: String
    let fullName: String
}

enum CreateUserError: Error {
    case invalidType
    case notUniqueEmail
    case internalError
}

enum UserLoginError: Error {
    case noUserFound
    case internalError
}

enum UserType: Content {
    case user
    case manager
}

extension DatabaseManager {
    func addUser(newUser: User) throws {
        let checkManagerQuery = managers.table
            .where(managers.emailColumn == newUser.email)
        
        let addUserQuery = users.table
            .insert(
                users.emailColumn <- newUser.email,
                users.passwordColumn <- newUser.password,
                users.fullNameColumn <- newUser.fullName,
                users.passportNumberColumn <- newUser.passportNumber,
                users.phoneNumberColumn <- newUser.phoneNumber,
                users.genderColumn <- newUser.gender)
        
        do {
            let sameEmailCount = try db.scalar(checkManagerQuery.count)
            if sameEmailCount > 0 {
                throw CreateUserError.notUniqueEmail
            }
            try db.run(addUserQuery)
        } catch let Result.error(_, code, _) where code == SQLITE_MISMATCH {
            throw CreateUserError.invalidType
        } catch let Result.error(_, code, _) where code == SQLITE_CONSTRAINT {
            throw CreateUserError.notUniqueEmail
        } catch _ {
            throw CreateUserError.internalError
        }
    }
    
    func addManager(newManager: Manager) throws {
        let checkQuery = users.table
            .where(users.emailColumn == newManager.email)
        
        let addManagerQuery = managers.table
            .insert(
                managers.emailColumn <- newManager.email,
                managers.passwordColumn <- newManager.password,
                managers.fullNameColumn <- newManager.fullName)
        do {
            let sameEmailCount = try db.scalar(checkQuery.count)
            if sameEmailCount > 0 {
                throw CreateUserError.notUniqueEmail
            }
            try db.run(addManagerQuery)
        } catch let Result.error(_, code, _) where code == SQLITE_MISMATCH {
            throw CreateUserError.invalidType
        } catch let Result.error(_, code, _) where code == SQLITE_CONSTRAINT {
            throw CreateUserError.notUniqueEmail
        } catch _ {
            throw CreateUserError.internalError
        }
    }
    
    func getUserData(loginData: LoginData) throws -> UserData {
        let query = users.table
            .where(users.table[users.emailColumn] == loginData.email)
            
        do {
            guard let userRow = try db.pluck(query) else {
                throw UserLoginError.noUserFound
            }
            
            let fullName = userRow[users.fullNameColumn]
            let passportNumber = userRow[users.passportNumberColumn]
            let phoneNumber = userRow[users.phoneNumberColumn]
            let email = userRow[users.emailColumn]
            let gender = userRow[users.genderColumn]
            
            let flightsQuery = query
                .join(tickets.table, on: tickets.table[tickets.emailColumn] == users.table[users.emailColumn])
                .join(flights.table, on:
                tickets.table[tickets.flightIdColumn] == flights.table[flights.idColumn])
            let flightsReturned = getFlightsFromQueries(queries: [flightsQuery])
            
            return UserData(
                fullName: fullName,
                passportNumber: passportNumber,
                phoneNumber: phoneNumber,
                email: email,
                gender: gender,
                flights: flightsReturned)
        } catch {
            print("Error getting UserData: \(error)")
            throw UserLoginError.noUserFound
        }
    }
    
    func verifyLogin(loginData: LoginData) -> UserType? {
        let verifyUserQuery = users.table
            .where(users.emailColumn == loginData.email)
            .where(users.passwordColumn == loginData.password)
        
        let verifyManagerQuery = managers.table
            .where(managers.emailColumn == loginData.email)
            .where(managers.passwordColumn == loginData.password)
        
        do {
            if let foundUser = try db.pluck(verifyUserQuery) {
                return UserType.user
            }
            if let foundManager = try db.pluck(verifyManagerQuery) {
                return UserType.manager
            }
        } catch {
            return nil
        }
        return nil
    }
    
//    func getUserTickets(loginData: LoginData) throws -> [Flight] {
//        let query = flights.table
//            .where(flights.departureIataColumn == from &&
//                   flights.arrivalIataColumn == to)
//        
//        var result: [Flight] = []
//        do {
//            for flight in try db.prepare(query) {
//                result.append(Flight(
//                    date: flight[flights.dateColumn],
//                    fromIata: flight[flights.departureIataColumn],
//                    fromDate: flight[flights.departureScheduledColumn],
//                    toIata: flight[flights.arrivalIataColumn],
//                    toDate: flight[flights.arrivalScheduledColumn],
//                    number: flight[flights.flightNumberColumn]))
//            }
//        } catch {}
//        return result
//    }
}
