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

extension DatabaseManager {
    func addUser(newUser: User) throws {
        let query = users.table
            .insert(
                users.emailColumn <- newUser.email,
                users.passwordColumn <- newUser.password,
                users.fullNameColumn <- newUser.fullName,
                users.passportNumberColumn <- newUser.passportNumber,
                users.phoneNumberColumn <- newUser.phoneNumber,
                users.genderColumn <- newUser.gender)
        
        do {
            try db.run(query)
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
            var userRow: Row? = nil
            for row in try db.prepare(query) {
                userRow = row
                break
            }
            guard let userRow = userRow else {
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
