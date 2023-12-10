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
//     let points: Int
}

struct UserData: Content {
    let name: String
    let flightIds: [Int]
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
            .where(users.emailColumn == loginData.email)
            .join(tickets.table, on: tickets.emailColumn == users.emailColumn)
        
        do {
            var name: String = ""
            var flightIds: [Int] = []
            for row in try db.prepare(query) {
                name = row[users.fullNameColumn]
                flightIds.append(row[tickets.flightIdColumn])
//                return User(
//                    email: row[users.emailColumn],
//                    password: row[users.passwordColumn],
//                    fullName: row[users.fullNameColumn],
//                    passportNumber: row[users.passportNumberColumn],
//                    phoneNumber: row[users.phoneNumberColumn],
//                    gender: row[users.genderColumn])
            }
            return UserData(name: name, flightIds: flightIds)
        } catch {
            throw UserLoginError.internalError
        }
        throw UserLoginError.noUserFound
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
