import Foundation
import SQLite

class DatabaseManager {
    private var db: Connection!

    private var countries: CountriesTable!
    
    init() {
        do {
            let path = "Resources/airmanager.sqlite3"
            db = try Connection(path)
            countries = CountriesTable(db: db)
        } catch {
            print("Error initializing database: \(error)")
        }
    }
    
    func getCountryIso2(countryName: String) -> String? {
        let query = countries.table
            .where(countries.nameColumn == countryName)
            .select(countries.iso2Column)
        
        do {
            for row in try db.prepare(query) {
                return row[countries.iso2Column]
            }
        } catch {
            return nil
        }
        return nil
    }

//    func getUsers() -> [String: Int] {
//        var result: [String: Int] = [:]
//
//        do {
//            let usersTable = Table("users")
//            let name = Expression<String>("name")
//            let age = Expression<Int>("age")
//
//            for user in try db.prepare(usersTable) {
//                result[user[name]] = user[age]
//            }
//        } catch {
//            print("Error retrieving users: \(error)")
//        }
//
//        return result
//    }
}

